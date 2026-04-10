#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const HELP = `
Download Figma MCP assets to feature-scoped folders.

Usage:
  node tool/download_figma_mcp_assets.mjs --assets <json_file> --feature <feature_name> [options]

Required:
  --assets      Path to JSON file containing asset URL mapping from Figma MCP.
  --feature     Feature name, e.g. home_demo.

Options:
  --icons-dir   Target icon directory. Default: assets/images/icons/<feature>
  --images-dir  Target image directory. Default: assets/images/<feature>
  --report      Output mapping report path. Default: spec/figma-assets/<feature>-asset-map.json
  --no-normalize-svg  Skip Flutter/mobile SVG normalization step.
  --overwrite   Overwrite existing files.
  --dry-run     Fetch and print mapping without writing files.
  --help        Show this message.
`;

function parseArgs(argv) {
  const args = new Map();
  const flags = new Set();

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      throw new Error(`Unknown argument: ${token}`);
    }

    const key = token.slice(2);
    if (
      key === 'overwrite'
      || key === 'dry-run'
      || key === 'help'
      || key === 'no-normalize-svg'
    ) {
      flags.add(key);
      continue;
    }

    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      throw new Error(`Missing value for ${token}`);
    }
    args.set(key, next);
    i += 1;
  }

  return {
    get(name, fallback = null) {
      return args.has(name) ? args.get(name) : fallback;
    },
    has(name) {
      return flags.has(name);
    },
  };
}

function toSnakeCase(value) {
  return String(value || '')
    .replace(/\.[^/.]+$/, '')
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .replace(/[^a-zA-Z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
    .toLowerCase();
}

function toCamelCase(value) {
  const parts = toSnakeCase(value)
    .split('_')
    .filter(Boolean);
  if (!parts.length) return 'asset';
  return parts[0] + parts.slice(1).map((item) => item[0].toUpperCase() + item.slice(1)).join('');
}

function toPascalCase(value) {
  return toSnakeCase(value)
    .split('_')
    .filter(Boolean)
    .map((item) => item[0].toUpperCase() + item.slice(1))
    .join('') || 'Asset';
}

function toPosix(value) {
  return String(value).replaceAll('\\', '/');
}

const ALLOWED_SVG_STYLE_KEYS = new Set([
  'fill',
  'stroke',
  'stroke-width',
  'stroke-linecap',
  'stroke-linejoin',
  'stroke-miterlimit',
  'stroke-dasharray',
  'stroke-dashoffset',
  'fill-rule',
  'clip-rule',
  'opacity',
  'fill-opacity',
  'stroke-opacity',
]);

function parseSvgStyleMap(styleString) {
  const output = new Map();
  for (const chunk of String(styleString || '').split(';')) {
    const line = chunk.trim();
    if (!line) continue;
    const index = line.indexOf(':');
    if (index <= 0) continue;
    const key = line.slice(0, index).trim().toLowerCase();
    const value = line.slice(index + 1).trim();
    if (!value || !ALLOWED_SVG_STYLE_KEYS.has(key)) continue;
    if (/^var\(/i.test(value)) continue;
    output.set(key, value);
  }
  return output;
}

function parseSvgStyle(styleString) {
  const parsed = parseSvgStyleMap(styleString);
  if (!parsed.size) return '';
  const output = [];
  for (const [key, value] of parsed.entries()) {
    output.push(`${key}="${value}"`);
  }
  return output.join(' ');
}

function extractSvgClassStyles(svgContent) {
  const classStyles = new Map();
  const styleBlockRegex = /<style\b[^>]*>([\s\S]*?)<\/style>/gi;
  let styleBlock;
  while ((styleBlock = styleBlockRegex.exec(svgContent)) !== null) {
    const css = styleBlock[1] || '';
    const classRuleRegex = /\.([a-zA-Z_][\w-]*)\s*\{([^}]*)\}/g;
    let classRule;
    while ((classRule = classRuleRegex.exec(css)) !== null) {
      const className = classRule[1];
      const parsed = parseSvgStyleMap(classRule[2]);
      if (!parsed.size) continue;
      const existing = classStyles.get(className) || new Map();
      for (const [key, value] of parsed.entries()) {
        existing.set(key, value);
      }
      classStyles.set(className, existing);
    }
  }
  return classStyles;
}

function applySvgClassStyles(svgContent, classStyles) {
  if (!classStyles.size) return svgContent;

  return svgContent.replace(/<([a-zA-Z][\w:.-]*)([^<>]*)>/g, (full, tagName, attrs) => {
    const tag = String(tagName || '').toLowerCase();
    if (tag === 'style' || tag === 'script' || tag === 'metadata' || tag === 'desc') {
      return full;
    }

    let nextAttrs = String(attrs || '');
    const classMatch = nextAttrs.match(/\sclass\s*=\s*["']([^"']+)["']/i);
    const inlineStyleDouble = nextAttrs.match(/\sstyle\s*=\s*"([^"]*)"/i);
    const inlineStyleSingle = nextAttrs.match(/\sstyle\s*=\s*'([^']*)'/i);
    const inlineStyleValue = inlineStyleDouble?.[1] ?? inlineStyleSingle?.[1] ?? '';

    nextAttrs = nextAttrs
      .replace(/\sclass\s*=\s*["'][^"']*["']/gi, '')
      .replace(/\sstyle\s*=\s*"[^"]*"/gi, '')
      .replace(/\sstyle\s*=\s*'[^']*'/gi, '');

    const mergedStyles = new Map();
    if (classMatch) {
      for (const className of classMatch[1].split(/\s+/).map((item) => item.trim()).filter(Boolean)) {
        const classStyle = classStyles.get(className);
        if (!classStyle) continue;
        for (const [key, value] of classStyle.entries()) {
          mergedStyles.set(key, value);
        }
      }
    }

    const inlineParsed = parseSvgStyleMap(inlineStyleValue);
    for (const [key, value] of inlineParsed.entries()) {
      mergedStyles.set(key, value);
    }

    if (!mergedStyles.size) {
      return `<${tagName}${nextAttrs}>`;
    }

    const existingAttrNames = new Set();
    nextAttrs.replace(/\s([:@a-zA-Z_][\w:.-]*)\s*=/g, (_, name) => {
      existingAttrNames.add(String(name).toLowerCase());
      return _;
    });

    for (const [key, value] of mergedStyles.entries()) {
      if (existingAttrNames.has(key.toLowerCase())) continue;
      nextAttrs += ` ${key}="${value}"`;
    }

    return `<${tagName}${nextAttrs}>`;
  });
}

function extractNumericSvgAttr(svgAttrs, attrName) {
  const regex = new RegExp(`\\s${attrName}\\s*=\\s*["']([^"']+)["']`, 'i');
  const match = svgAttrs.match(regex);
  if (!match) return null;
  const value = String(match[1]).trim().replace(/px$/i, '');
  const number = Number.parseFloat(value);
  if (!Number.isFinite(number) || number <= 0) return null;
  return number;
}

function formatSvgNumber(value) {
  if (Number.isInteger(value)) return String(value);
  const rounded = Number(value.toFixed(3));
  return String(rounded).replace(/\.0+$/, '').replace(/(\.\d*[1-9])0+$/, '$1');
}

function normalizeSvgRoot(svgContent) {
  return svgContent.replace(/<svg\b([^>]*)>/i, (full, attrs) => {
    let nextAttrs = attrs;
    if (!/\sxmlns\s*=/.test(nextAttrs)) {
      nextAttrs += ' xmlns="http://www.w3.org/2000/svg"';
    }

    nextAttrs = nextAttrs.replace(
      /\s(width|height)\s*=\s*["']([^"']*?)px["']/gi,
      (_, key, value) => ` ${String(key).toLowerCase()}="${value}"`,
    );

    if (!/\sviewBox\s*=/.test(nextAttrs)) {
      const width = extractNumericSvgAttr(nextAttrs, 'width');
      const height = extractNumericSvgAttr(nextAttrs, 'height');
      if (width && height) {
        nextAttrs += ` viewBox="0 0 ${formatSvgNumber(width)} ${formatSvgNumber(height)}"`;
      }
    }

    return `<svg${nextAttrs}>`;
  });
}

function normalizeSvgForFlutter(svgInput) {
  let svg = String(svgInput || '');
  svg = svg.replace(/^\uFEFF/, '');
  svg = svg.replace(/<\?xml[\s\S]*?\?>/gi, '');
  svg = svg.replace(/<!DOCTYPE[\s\S]*?>/gi, '');
  svg = svg.replace(/<!--[\s\S]*?-->/g, '');

  const classStyles = extractSvgClassStyles(svg);
  svg = applySvgClassStyles(svg, classStyles);

  // Remove unsupported/non-rendering tags for flutter_svg mobile rendering.
  svg = svg.replace(/<script\b[\s\S]*?<\/script>/gi, '');
  svg = svg.replace(/<foreignObject\b[\s\S]*?<\/foreignObject>/gi, '');
  svg = svg.replace(/<style\b[\s\S]*?<\/style>/gi, '');
  svg = svg.replace(/<metadata\b[\s\S]*?<\/metadata>/gi, '');
  svg = svg.replace(/<desc\b[\s\S]*?<\/desc>/gi, '');
  svg = svg.replace(/<filter\b[\s\S]*?<\/filter>/gi, '');

  // Remove attributes commonly tied to unsupported effects or web-only data.
  svg = svg.replace(/\sfilter\s*=\s*["']url\([^"']*?\)["']/gi, '');
  svg = svg.replace(/\sclass\s*=\s*["'][^"']*["']/gi, '');
  svg = svg.replace(/\sdata-[\w-]+\s*=\s*["'][^"']*["']/gi, '');
  svg = svg.replace(/\sxlink:href\s*=\s*["']([^"']+)["']/gi, ' href="$1"');
  svg = svg.replace(/\sxmlns:xlink\s*=\s*["'][^"']*["']/gi, '');

  // Expand inline style attr into explicit SVG attrs where possible.
  svg = svg.replace(/\sstyle\s*=\s*"([^"]*)"/gi, (_, styleValue) => {
    const attrs = parseSvgStyle(styleValue);
    return attrs ? ` ${attrs}` : '';
  });
  svg = svg.replace(/\sstyle\s*=\s*'([^']*)'/gi, (_, styleValue) => {
    const attrs = parseSvgStyle(styleValue);
    return attrs ? ` ${attrs}` : '';
  });

  svg = normalizeSvgRoot(svg);
  svg = svg.replace(/>\s+</g, '><').trim();
  if (!svg.endsWith('\n')) svg += '\n';
  return svg;
}

function resolveEntries(raw) {
  if (Array.isArray(raw)) {
    return raw
      .map((item, index) => {
        if (typeof item === 'string') {
          return { key: `asset_${index + 1}`, url: item };
        }
        if (item && typeof item === 'object') {
          const key = String(item.key ?? item.name ?? item.id ?? `asset_${index + 1}`);
          const url = item.url ?? item.src ?? item.href;
          return { key, url: typeof url === 'string' ? url : null };
        }
        return null;
      })
      .filter(Boolean)
      .filter((item) => item.url);
  }

  if (raw && typeof raw === 'object') {
    const nested = raw.assets ?? raw.downloadUrls ?? raw.urls;
    if (nested && typeof nested === 'object') {
      return resolveEntries(nested);
    }

    return Object.entries(raw)
      .filter(([, value]) => typeof value === 'string')
      .map(([key, value]) => ({ key, url: value }));
  }

  return [];
}

function extensionFromContentType(contentType) {
  const type = String(contentType || '').toLowerCase();
  if (type.includes('image/svg+xml')) return '.svg';
  if (type.includes('image/png')) return '.png';
  if (type.includes('image/jpeg')) return '.jpg';
  if (type.includes('image/webp')) return '.webp';
  if (type.includes('image/gif')) return '.gif';
  return null;
}

function extensionFromPathname(urlString) {
  try {
    const ext = path.extname(new URL(urlString).pathname || '').toLowerCase();
    if (['.svg', '.png', '.jpg', '.jpeg', '.webp', '.gif'].includes(ext)) {
      return ext === '.jpeg' ? '.jpg' : ext;
    }
    return null;
  } catch {
    return null;
  }
}

function extensionFromBuffer(buffer) {
  const head = buffer.subarray(0, 64).toString('utf8').trimStart().toLowerCase();
  if (head.startsWith('<svg') || head.startsWith('<?xml')) return '.svg';
  if (buffer.length >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
    return '.png';
  }
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return '.jpg';
  }
  if (buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP') {
    return '.webp';
  }
  return '.bin';
}

async function ensureUniquePath(basePath, overwrite) {
  if (overwrite) return basePath;

  try {
    await fs.access(basePath);
  } catch {
    return basePath;
  }

  const ext = path.extname(basePath);
  const name = basePath.slice(0, -ext.length);
  let index = 1;
  while (true) {
    const candidate = `${name}_${index}${ext}`;
    try {
      await fs.access(candidate);
      index += 1;
    } catch {
      return candidate;
    }
  }
}

function guessIsIcon(entryKey, ext) {
  if (ext === '.svg') return true;
  return /(^|[_-])(icon|icons|ic)($|[_-])/i.test(entryKey);
}

async function downloadAsset(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} for ${url}`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  return {
    buffer,
    contentType: response.headers.get('content-type'),
  };
}

function buildConstantName({ feature, key, ext, isIcon }) {
  const featurePrefix = toCamelCase(feature);
  const featureSnake = toSnakeCase(feature);
  const normalizedKey = toSnakeCase(key);
  let trimmedKey = normalizedKey.startsWith(`${featureSnake}_`)
    ? normalizedKey.slice(featureSnake.length + 1)
    : normalizedKey;
  if (isIcon && trimmedKey.startsWith('icon_')) {
    trimmedKey = trimmedKey.slice('icon_'.length);
  }
  if (!isIcon && (trimmedKey.startsWith('img_') || trimmedKey.startsWith('image_'))) {
    trimmedKey = trimmedKey.replace(/^img_|^image_/, '');
  }
  const keyName = toPascalCase(trimmedKey || normalizedKey);
  const suffix = ext.replace('.', '');
  const extSuffix = suffix ? suffix[0].toUpperCase() + suffix.slice(1) : 'Asset';
  const typePrefix = isIcon ? 'Icon' : 'Img';
  return `${featurePrefix}${typePrefix}${keyName}${extSuffix}`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.has('help')) {
    console.log(HELP.trim());
    return;
  }

  const assetsPath = args.get('assets');
  const feature = args.get('feature');
  if (!assetsPath || !feature) {
    throw new Error('Missing required options: --assets and --feature');
  }

  const iconsDir = args.get('icons-dir', path.join('assets', 'images', 'icons', feature));
  const imagesDir = args.get('images-dir', path.join('assets', 'images', feature));
  const reportPath = args.get('report', path.join('spec', 'figma-assets', `${feature}-asset-map.json`));
  const overwrite = args.has('overwrite');
  const dryRun = args.has('dry-run');
  const normalizeSvg = !args.has('no-normalize-svg');

  const rawContent = await fs.readFile(assetsPath, 'utf8');
  const parsed = JSON.parse(rawContent);
  const entries = resolveEntries(parsed).filter((item) => /^https?:\/\//i.test(item.url));

  if (!entries.length) {
    throw new Error(`No valid URL entries found in: ${assetsPath}`);
  }

  const reportItems = [];
  let successCount = 0;
  let failureCount = 0;

  for (const item of entries) {
    const rawKey = item.key || 'asset';
    const normalizedKey = toSnakeCase(rawKey) || 'asset';

    try {
      const { buffer, contentType } = await downloadAsset(item.url);
      const ext =
        extensionFromPathname(item.url)
        || extensionFromContentType(contentType)
        || extensionFromBuffer(buffer);

      const isIcon = guessIsIcon(normalizedKey, ext);
      const targetDir = isIcon ? iconsDir : imagesDir;
      const targetName = `${normalizedKey}${ext}`;
      const absoluteTarget = await ensureUniquePath(path.resolve(targetDir, targetName), overwrite);
      const relativeTarget = toPosix(path.relative(process.cwd(), absoluteTarget) || absoluteTarget);
      const constantName = buildConstantName({
        feature,
        key: normalizedKey,
        ext,
        isIcon,
      });

      let finalBuffer = buffer;
      if (ext === '.svg' && normalizeSvg) {
        const normalized = normalizeSvgForFlutter(buffer.toString('utf8'));
        finalBuffer = Buffer.from(normalized, 'utf8');
      }

      if (!dryRun) {
        await fs.mkdir(path.dirname(absoluteTarget), { recursive: true });
        await fs.writeFile(absoluteTarget, finalBuffer);
      }

      reportItems.push({
        key: rawKey,
        url: item.url,
        type: isIcon ? 'icon' : 'image',
        output: relativeTarget,
        constantName,
        normalizedSvg: ext === '.svg' ? normalizeSvg : false,
        contentType: contentType || '',
      });
      successCount += 1;
      console.log(`${dryRun ? '[DRY-RUN] ' : ''}Saved ${rawKey} -> ${relativeTarget}`);
    } catch (error) {
      failureCount += 1;
      console.error(`Failed ${rawKey}: ${error.message}`);
    }
  }

  const report = {
    feature,
    source: toPosix(path.relative(process.cwd(), path.resolve(assetsPath))),
    generatedAt: new Date().toISOString(),
    total: entries.length,
    success: successCount,
    failed: failureCount,
    items: reportItems,
  };

  const reportAbsolute = path.resolve(reportPath);
  if (!dryRun) {
    await fs.mkdir(path.dirname(reportAbsolute), { recursive: true });
    await fs.writeFile(reportAbsolute, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(`Report written: ${toPosix(path.relative(process.cwd(), reportAbsolute))}`);
  } else {
    console.log(JSON.stringify(report, null, 2));
  }

  if (failureCount > 0) {
    process.exitCode = 2;
  }
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
});
