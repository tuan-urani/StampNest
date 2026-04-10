import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { parse } from '@babel/parser'
import traverseModule from '@babel/traverse'
const traverse = traverseModule.default
import postcss from 'postcss'
import safeParser from 'postcss-safe-parser'

const __dirname = path.dirname(new URL(import.meta.url).pathname)
const require = createRequire(import.meta.url)
let sass = null
try {
  sass = require('sass')
} catch {}

const REPO_ROOT = path.resolve(__dirname, '../..')
const APP_ASSETS_FILE = path.resolve(REPO_ROOT, 'lib/src/utils/app_assets.dart')
let ICONS_MAP = {}
try {
  const mapPath = path.resolve(__dirname, 'icons_map.json')
  if (fs.existsSync(mapPath)) ICONS_MAP = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
} catch {}

let ASSET_CONTEXT = null
const DEFAULT_ASSET_DIR = process.env.JSX2FLUTTER_ASSET_DIR || 'assets/figma'
const GENERIC_ASSET_TOKENS = new Set([
  'asset',
  'auto',
  'div',
  'ellipse',
  'frame',
  'group',
  'icon',
  'image',
  'img',
  'line',
  'path',
  'rect',
  'shape',
  'svg',
  'vector',
  'wrapper',
])

function normalizeAssetPath(p) {
  return p.replace(/\\/g, '/')
}

function sanitizeAssetToken(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_')
}

function normalizeSemanticAssetToken(value) {
  const base = sanitizeAssetToken(value)
  if (!base) return ''
  const withoutPrefix = base.replace(/^(icon|image|img|ic)_+/, '')
  const trimmed = withoutPrefix
    .replace(/(_?\d+)+$/g, '')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
  return trimmed || withoutPrefix || base
}

function isGenericSemanticToken(token) {
  const normalized = normalizeSemanticAssetToken(token)
  if (!normalized) return true
  if (GENERIC_ASSET_TOKENS.has(normalized)) return true
  if (/^(frame|group|rect|ellipse|vector|path|shape|line|icon|img|image)\d*$/.test(normalized)) return true
  if (/^[a-z0-9]{6,}(?:_[a-z0-9]{5,})+$/.test(normalized) && /\d/.test(normalized)) return true
  if (/^\d+$/.test(normalized)) return true
  return false
}

function pickSemanticAssetToken(absPath, semanticHint, stem) {
  const directHint = normalizeSemanticAssetToken(semanticHint)
  if (directHint && !isGenericSemanticToken(directHint)) return directHint

  const mappedHint = normalizeSemanticAssetToken(ASSET_CONTEXT?.semanticHintByAbs?.get(absPath))
  if (mappedHint && !isGenericSemanticToken(mappedHint)) return mappedHint

  const stemHint = normalizeSemanticAssetToken(stem)
  if (stemHint && !isGenericSemanticToken(stemHint)) return stemHint

  return ''
}

function toAssetAbsPath(src, baseDir) {
  if (!src || !baseDir) return null
  const cleaned = String(src).split('?')[0].split('#')[0]
  if (!cleaned || /^https?:\/\//i.test(cleaned) || /^data:/i.test(cleaned)) return null
  const abs = path.resolve(baseDir, cleaned)
  if (!fs.existsSync(abs)) return null
  return abs
}

function buildAssetOutputName(absPath, semanticHint = '') {
  if (!ASSET_CONTEXT || !ASSET_CONTEXT.renameAssets) {
    return path.basename(absPath)
  }
  const existing = ASSET_CONTEXT.fileNameByAbs.get(absPath)
  if (existing) return existing

  const extRaw = path.extname(absPath).toLowerCase()
  const ext = extRaw || '.bin'
  const stemRaw = path.basename(absPath, extRaw)
  const stem = sanitizeAssetToken(stemRaw) || 'asset'
  const prefix = sanitizeAssetToken(ASSET_CONTEXT.assetPrefix)
  const kind = ext === '.svg' ? 'ic' : 'img'
  const semanticPart = pickSemanticAssetToken(absPath, semanticHint, stem) || (ext === '.svg' ? 'icon' : 'image')
  const base = [kind, prefix, semanticPart].filter(Boolean).join('_')

  let candidate = `${base}${ext}`
  let index = 2
  while (ASSET_CONTEXT.usedFileNames.has(candidate)) {
    candidate = `${base}_${index}${ext}`
    index += 1
  }

  ASSET_CONTEXT.usedFileNames.add(candidate)
  ASSET_CONTEXT.fileNameByAbs.set(absPath, candidate)
  return candidate
}

function registerAsset(absPath, relPath) {
  if (!ASSET_CONTEXT) return
  ASSET_CONTEXT.assets.set(absPath, relPath)
}

function resolveLocalAsset(src, semanticHint = '') {
  if (!src || !ASSET_CONTEXT) return null
  const abs = toAssetAbsPath(src, ASSET_CONTEXT.jsxDir)
  if (!abs) return null
  const fileName = buildAssetOutputName(abs, semanticHint)
  const rel = normalizeAssetPath(path.posix.join(ASSET_CONTEXT.assetDir, fileName))
  const assetRef = resolveAssetReference(rel)
  registerAsset(abs, rel)
  return {
    rel,
    isSvg: fileName.toLowerCase().endsWith('.svg'),
    assetRef,
  }
}

function copyCollectedAssets() {
  if (!ASSET_CONTEXT || !ASSET_CONTEXT.copyAssets) return
  if (!ASSET_CONTEXT.assets.size) return
  for (const [abs, rel] of ASSET_CONTEXT.assets.entries()) {
    const dest = path.resolve(REPO_ROOT, rel)
    ensureDir(path.dirname(dest))
    try {
      fs.copyFileSync(abs, dest)
    } catch {}
  }
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true })
}

function semanticTokenFromClassName(className) {
  const token = normalizeSemanticAssetToken(className)
  if (!token || isGenericSemanticToken(token)) return ''
  return token
}

function isBetterSemanticToken(nextToken, currentToken) {
  if (!currentToken) return true
  const currentGeneric = isGenericSemanticToken(currentToken)
  const nextGeneric = isGenericSemanticToken(nextToken)
  if (currentGeneric !== nextGeneric) return !nextGeneric
  if (nextToken.length !== currentToken.length) return nextToken.length < currentToken.length
  return nextToken < currentToken
}

function collectAssetSemanticHints(ast, jsxDir) {
  const semanticHints = new Map()
  traverse(ast, {
    JSXElement(pathNode) {
      const el = pathNode.node
      if (jsxElementName(el).toLowerCase() !== 'img') return
      const src = getAttr(el, 'src') || ''
      const abs = toAssetAbsPath(src, jsxDir)
      if (!abs) return
      const hint = semanticTokenFromClassName(getClassNameAttr(el))
      if (!hint) return
      const existing = semanticHints.get(abs)
      if (!existing || isBetterSemanticToken(hint, existing)) {
        semanticHints.set(abs, hint)
      }
    }
  })
  return semanticHints
}

function toPascalCaseToken(raw) {
  const token = sanitizeAssetToken(raw)
  if (!token) return ''
  return token
    .split('_')
    .filter(Boolean)
    .map(part => part[0].toUpperCase() + part.slice(1))
    .join('')
}

function toWidgetClassName(raw) {
  const normalized = String(raw || '')
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .replace(/[^A-Za-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .toLowerCase()
  if (!normalized) return 'FigmaWidget'
  const className = normalized
    .split('_')
    .filter(Boolean)
    .map(part => part[0].toUpperCase() + part.slice(1))
    .join('')
  if (!className) return 'FigmaWidget'
  return /^[A-Za-z_]/.test(className) ? className : `Figma${className}`
}

function buildAppAssetConstName(assetPath) {
  const normalized = normalizeAssetPath(assetPath).replace(/^assets\//, '')
  const parts = normalized
    .split(/[\/._-]+/)
    .map(part => sanitizeAssetToken(part))
    .filter(Boolean)
  if (!parts.length) return 'assetGenerated'
  const [head, ...tail] = parts
  const headName = /^[a-z]/.test(head) ? head : `asset${toPascalCaseToken(head)}`
  return `${headName}${tail.map(toPascalCaseToken).join('')}`
}

function loadAppAssetsRegistry() {
  if (!fs.existsSync(APP_ASSETS_FILE)) return null
  let content = ''
  try {
    content = fs.readFileSync(APP_ASSETS_FILE, 'utf8')
  } catch {
    return null
  }
  const pathToConst = new Map()
  const constToPath = new Map()
  const regex = /static const String (\w+)\s*=\s*'([^']+)';/g
  let match
  while ((match = regex.exec(content)) !== null) {
    const constName = match[1]
    const assetPath = normalizeAssetPath(match[2])
    constToPath.set(constName, assetPath)
    if (!pathToConst.has(assetPath)) pathToConst.set(assetPath, constName)
  }
  return {
    pathToConst,
    constToPath,
    pendingPathToConst: new Map(),
    pendingConstNames: new Set(),
  }
}

function resolveAppAssetConstName(assetPath) {
  const registry = ASSET_CONTEXT?.appAssetsRegistry
  if (!registry) return null
  const normalized = normalizeAssetPath(assetPath)
  const existing = registry.pathToConst.get(normalized) || registry.pendingPathToConst.get(normalized)
  if (existing) return existing
  const base = buildAppAssetConstName(normalized)
  let candidate = base
  let index = 2
  while (
    registry.constToPath.has(candidate) ||
    registry.pendingConstNames.has(candidate)
  ) {
    candidate = `${base}${index}`
    index += 1
  }
  registry.pathToConst.set(normalized, candidate)
  registry.pendingPathToConst.set(normalized, candidate)
  registry.pendingConstNames.add(candidate)
  return candidate
}

function resolveAssetReference(assetPath) {
  const constName = resolveAppAssetConstName(assetPath)
  if (constName) return `AppAssets.${constName}`
  return toDartLiteral(assetPath)
}

function syncAppAssetsFile() {
  const registry = ASSET_CONTEXT?.appAssetsRegistry
  if (!registry || !registry.pendingPathToConst.size) return
  if (!fs.existsSync(APP_ASSETS_FILE)) return
  let content = ''
  try {
    content = fs.readFileSync(APP_ASSETS_FILE, 'utf8')
  } catch {
    return
  }
  const insertAt = content.lastIndexOf('\n}')
  if (insertAt < 0) return
  const lines = [...registry.pendingPathToConst.entries()]
    .sort((a, b) => a[1].localeCompare(b[1]))
    .map(([assetPath, constName]) => `  static const String ${constName} = '${assetPath}';`)
  if (!lines.length) return
  const block = `\n${lines.join('\n')}\n`
  const updated = `${content.slice(0, insertAt)}${block}${content.slice(insertAt)}`
  fs.writeFileSync(APP_ASSETS_FILE, updated, 'utf8')
  registry.pendingPathToConst.clear()
  registry.pendingConstNames.clear()
}

function readFile(p) {
  return fs.readFileSync(p, 'utf8')
}

function writeFile(p, content) {
  ensureDir(path.dirname(p))
  fs.writeFileSync(p, content, 'utf8')
}

function compileScssIfNeeded(css, cssPath) {
  // If dart-sass is available, use it (most accurate).
  if (!sass) return css
  try {
    const result = sass.compileString(css, {
      style: 'expanded',
      loadPaths: cssPath ? [path.dirname(cssPath)] : []
    })
    return result.css || css
  } catch {
    return css
  }
}

function stripInlineComment(line) {
  // Keep URLs like http://... by only treating '//' as a comment start when it's not in quotes.
  const s = String(line)
  let inSingle = false
  let inDouble = false
  for (let i = 0; i < s.length - 1; i++) {
    const ch = s[i]
    const next = s[i + 1]
    if (ch === "'" && !inDouble) inSingle = !inSingle
    if (ch === '"' && !inSingle) inDouble = !inDouble
    if (!inSingle && !inDouble && ch === '/' && next === '/') {
      return s.slice(0, i)
    }
  }
  return s
}

function splitSelectors(sel) {
  return String(sel)
    .split(',')
    .map(s => s.trim())
    .filter(Boolean)
}

function combineSelectors(parents, current) {
  const cur = splitSelectors(current)
  if (!cur.length) return parents
  const out = []
  for (const p of parents) {
    for (const c of cur) {
      if (!p) {
        out.push(c)
      } else if (c.includes('&')) {
        out.push(c.replace(/&/g, p))
      } else {
        out.push(`${p} ${c}`)
      }
    }
  }
  return out
}

function flattenScssToCss(scss) {
  // Minimal SCSS flattener: handles nested selectors with braces.
  // This is enough for Figma/Trae-generated SCSS modules (no mixins/functions).
  const lines = String(scss).replace(/\r\n/g, '\n').split('\n')
  const stack = [{ selectors: [''], decls: [] }]
  let inBlockComment = false
  const outRules = []
  let pendingDecl = null

  function flushTop() {
    const top = stack[stack.length - 1]
    if (!top || !top.decls.length) return
    const decls = top.decls.join('\n')
    for (const sel of top.selectors) {
      if (!sel) continue
      outRules.push(`${sel} {\n${decls}\n}`)
    }
    top.decls = []
  }

  for (let rawLine of lines) {
    let line = String(rawLine)
    // Block comments /* ... */
    if (inBlockComment) {
      const end = line.indexOf('*/')
      if (end >= 0) {
        inBlockComment = false
        line = line.slice(end + 2)
      } else {
        continue
      }
    }
    while (true) {
      const start = line.indexOf('/*')
      if (start < 0) break
      const end = line.indexOf('*/', start + 2)
      if (end >= 0) {
        line = line.slice(0, start) + line.slice(end + 2)
      } else {
        inBlockComment = true
        line = line.slice(0, start)
        break
      }
    }

    line = stripInlineComment(line).trim()
    if (!line) continue

    if (pendingDecl) {
      pendingDecl.value = `${pendingDecl.value} ${line}`.trim()
      if (pendingDecl.value.includes(';')) {
        const semicolonIndex = pendingDecl.value.indexOf(';')
        const declValue = pendingDecl.value.slice(0, semicolonIndex + 1).trim()
        stack[stack.length - 1].decls.push(`  ${pendingDecl.prop}: ${declValue}`)
        pendingDecl = null
      }
      continue
    }

    // Handle multiple braces on same line crudely by iterating chars.
    // We avoid full tokenization by treating declarations as whole lines.
    // Common generator output keeps '{' on selector line and '}' on its own line.
    if (line.endsWith('{')) {
      const selector = line.slice(0, -1).trim()
      const parentSelectors = stack[stack.length - 1]?.selectors || ['']
      const selectors = combineSelectors(parentSelectors, selector)
      stack.push({ selectors, decls: [] })
      continue
    }
    if (line === '}') {
      if (pendingDecl) pendingDecl = null
      flushTop()
      stack.pop()
      continue
    }
    // Declaration line (supports multiline values like linear-gradient(...))
    if (line.includes(':')) {
      // Only accept standard declarations (avoid mis-parsing nested selectors)
      const idx = line.indexOf(':')
      const prop = line.slice(0, idx).trim()
      const val = line.slice(idx + 1).trim()
      if (prop && /^[a-zA-Z_-][a-zA-Z0-9_-]*$/.test(prop)) {
        if (val.includes(';')) {
          const semicolonIndex = val.indexOf(';')
          const declValue = val.slice(0, semicolonIndex + 1).trim()
          stack[stack.length - 1].decls.push(`  ${prop}: ${declValue}`)
        } else {
          pendingDecl = { prop, value: val }
        }
      }
      continue
    }
  }

  // Flush any remaining
  while (stack.length > 1) {
    flushTop()
    stack.pop()
  }
  return outRules.join('\n\n')
}

function compileOrFlattenScss(css, cssPath) {
  if (sass) return compileScssIfNeeded(css, cssPath)
  try {
    return flattenScssToCss(css)
  } catch {
    return css
  }
}

function parseCssModules(css, cssPath) {
  const normalizedCss = compileOrFlattenScss(css, cssPath)
  const root = postcss.parse(normalizedCss, { parser: safeParser })
  const map = {}
  root.walkRules(rule => {
    const selector = rule.selector
    if (!selector) return
    const props = {}
    rule.walkDecls(decl => {
      props[decl.prop] = decl.value
    })
    const classes = [...selector.matchAll(/\.([A-Za-z0-9_-]+)/g)].map(m => m[1])
    if (classes.length) {
      const key = classes[classes.length - 1]
      map[key] = { ...(map[key] || {}), ...props }
    }
  })
  return map
}

function cssColorToAppColor(v) {
  const raw = v.trim().toLowerCase()
  // CSS variable tokens mapping -> AppColors
  const varMatch = raw.match(/^var\(\s*--?([a-z0-9\-_]+)\s*(?:,\s*([^)]+))?\)$/i)
  if (varMatch) {
    const token = varMatch[1]
    const tok = token.replace(/[^a-z0-9_]/gi, '').toLowerCase()
    const dict = {
      primary: 'AppColors.primary',
      buttondarkbtndarkcolor: 'AppColors.white',
      text2: 'AppColors.colorB8BCC6',
      tabdisabletext: 'AppColors.colorB7B7B7',
      neutrals200: 'AppColors.colorEAECF0',
      titletext: 'AppColors.color667394',
      bg: 'AppColors.background',
    }
    const mapped = dict[tok]
    if (mapped) return mapped
    const fallback = varMatch[2]
    if (fallback) return cssColorToAppColor(fallback)
    return null
  }
  const hex = raw
  if (/^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/.test(hex)) {
    // Expand short hex (#abc / #rgba) and normalize alpha order
    if (/^#[0-9a-f]{3}$/.test(hex)) {
      const r = hex[1], g = hex[2], b = hex[3]
      return `AppColors.fromHex('#${r}${r}${g}${g}${b}${b}')`
    }
    if (/^#[0-9a-f]{4}$/.test(hex)) {
      const r = hex[1], g = hex[2], b = hex[3], a = hex[4]
      // CSS #RGBA -> Flutter expects #AARRGGBB
      return `AppColors.fromHex('#${a}${a}${r}${r}${g}${g}${b}${b}')`
    }
    if (/^#[0-9a-f]{8}$/.test(hex)) {
      const rr = hex.slice(1, 3)
      const gg = hex.slice(3, 5)
      const bb = hex.slice(5, 7)
      const aa = hex.slice(7, 9)
      return `AppColors.fromHex('#${aa}${rr}${gg}${bb}')`
    }
    return `AppColors.fromHex('${hex}')`
  }
  const rgbMatch = raw.match(/^rgba?\((\s*\d+\s*),(\s*\d+\s*),(\s*\d+\s*)(?:,\s*(\d*\.?\d+)\s*)?\)$/i)
  if (rgbMatch) {
    const r = Math.max(0, Math.min(255, parseInt(rgbMatch[1])))
    const g = Math.max(0, Math.min(255, parseInt(rgbMatch[2])))
    const b = Math.max(0, Math.min(255, parseInt(rgbMatch[3])))
    const a = rgbMatch[4] != null ? Math.max(0, Math.min(1, parseFloat(rgbMatch[4]))) : 1
    const aa = Math.round(a * 255)
    const hexStr = `#${aa.toString(16).padStart(2,'0')}${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`
    return `AppColors.fromHex('${hexStr}')`
  }
  if (hex === 'white') return 'AppColors.white'
  if (hex === 'black') return 'AppColors.black'
  if (hex === 'transparent') return 'AppColors.transparent'
  return null
}

function extractLinearGradientArgs(str) {
  const source = String(str || '')
  const marker = 'linear-gradient('
  const start = source.toLowerCase().indexOf(marker)
  if (start < 0) return null

  let depth = 1
  let args = ''
  for (let i = start + marker.length; i < source.length; i += 1) {
    const ch = source[i]
    if (ch === '(') {
      depth += 1
      args += ch
      continue
    }
    if (ch === ')') {
      depth -= 1
      if (depth === 0) break
      args += ch
      continue
    }
    args += ch
  }
  if (depth !== 0) return null
  return args
}

function parseGradientColors(str) {
  const args = extractLinearGradientArgs(str)
  if (!args) return []
  const rawColors = [...args.matchAll(/#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{4}|[0-9a-f]{3})/ig)].map(x => x[0])
  return rawColors.map(c => cssColorToAppColor(c)).filter(Boolean)
}

function parseLinearGradient(str) {
  const args = extractLinearGradientArgs(str)
  if (!args) return null
  const colors = parseGradientColors(str)
  if (!colors.length) return null
  const angleMatch = args.match(/(\d+)\s*deg/i)
  const angle = angleMatch ? parseInt(angleMatch[1]) : 180
  let begin = 'Alignment.topLeft', end = 'Alignment.bottomRight'
  if (angle === 180) { begin = 'Alignment.topCenter'; end = 'Alignment.bottomCenter' }
  if (angle === 90) { begin = 'Alignment.centerLeft'; end = 'Alignment.centerRight' }
  return `LinearGradient(begin: ${begin}, end: ${end}, colors: [${colors.join(', ')}])`
}

function gradientTextFromProps(props) {
  const clip = `${props['background-clip'] || ''} ${props['-webkit-background-clip'] || ''}`.toLowerCase()
  if (!clip.includes('text')) return null
  const gradientSource = props['background-image'] || props['background']
  if (!gradientSource || !/linear-gradient/i.test(String(gradientSource))) return null
  return parseLinearGradient(gradientSource)
}

function cssPxToDouble(v) {
  const m = String(v).match(/([0-9.]+)px/)
  if (m) return parseFloat(m[1])
  const n = parseFloat(v)
  if (!Number.isNaN(n)) return n
  return null
}

function parseBoxValues(v) {
  if (!v) return null
  const cleaned = String(v).split('/')[0]
  const parts = cleaned.trim().split(/\s+/).filter(Boolean)
  const nums = parts.map(cssPxToDouble).filter(n => n != null)
  if (!nums.length) return null
  if (nums.length === 1) return { top: nums[0], right: nums[0], bottom: nums[0], left: nums[0] }
  if (nums.length === 2) return { top: nums[0], right: nums[1], bottom: nums[0], left: nums[1] }
  if (nums.length === 3) return { top: nums[0], right: nums[1], bottom: nums[2], left: nums[1] }
  return { top: nums[0], right: nums[1], bottom: nums[2], left: nums[3] }
}

function fontWeightFromCss(v) {
  const raw = String(v || '').trim().toLowerCase()
  if (raw === 'bold') return 'FontWeight.w700'
  if (raw === 'normal') return 'FontWeight.w400'
  const n = parseInt(raw, 10)
  if (n >= 700) return 'FontWeight.w700'
  if (n >= 600) return 'FontWeight.w600'
  if (n >= 500) return 'FontWeight.w500'
  return 'FontWeight.w400'
}

function fontFamilyFromCss(v) {
  if (!v) return null
  const fontMap = {
    'zen maru gothic': 'ZenMaruGothic',
    'noto sans jp': 'ZenMaruGothic',
    'sf pro text': null,
    'inter': null,
  }
  const candidates = String(v)
    .split(',')
    .map(s => s.trim().replace(/^['"]|['"]$/g, ''))
    .filter(Boolean)
  for (const name of candidates) {
    const key = name.toLowerCase()
    if (Object.prototype.hasOwnProperty.call(fontMap, key)) {
      const mapped = fontMap[key]
      return mapped ? toDartLiteral(mapped) : null
    }
    if (key.includes('sans-serif') || key.includes('serif') || key.includes('monospace')) continue
    return toDartLiteral(name)
  }
  return null
}

function textStyleFromProps(props) {
  const size = cssPxToDouble(props['font-size'])
  const weight = props['font-weight'] ? fontWeightFromCss(props['font-weight']) : null
  let color = props['color'] ? cssColorToAppColor(props['color']) : null
  if (color === 'AppColors.transparent') {
    // Figma CSS often exports gradient text as:
    // color: transparent; background: linear-gradient(...); background-clip: text.
    // Flutter Text doesn't support CSS background-clip, so fallback to first gradient color.
    const clip = `${props['background-clip'] || ''} ${props['-webkit-background-clip'] || ''}`.toLowerCase()
    if (clip.includes('text')) {
      const gradientSource = props['background-image'] || props['background']
      const gradientColors = parseGradientColors(gradientSource)
      if (gradientColors.length) color = gradientColors[0]
    }
  }
  const lineHeight = cssPxToDouble(props['line-height'])
  const heightRatio = size && lineHeight ? (lineHeight / size) : null
  const fontFamily = fontFamilyFromCss(props['font-family'])
  const letterSpacing = cssPxToDouble(props['letter-spacing'])
  if (!size && !weight && !color && !heightRatio && !fontFamily && letterSpacing == null) return null
  const args = []
  if (fontFamily) args.push(`fontFamily: ${fontFamily}`)
  if (size) args.push(`fontSize: ${size}`)
  if (color) args.push(`color: ${color}`)
  if (weight) args.push(`fontWeight: ${weight}`)
  if (heightRatio) args.push(`height: ${heightRatio}`)
  if (letterSpacing != null) args.push(`letterSpacing: ${letterSpacing}`)
  return `TextStyle(${args.join(', ')})`
}

function textAlignFromProps(props) {
  const align = String(props['text-align'] || '').toLowerCase()
  if (align === 'center') return 'TextAlign.center'
  if (align === 'right' || align === 'end') return 'TextAlign.right'
  if (align === 'left' || align === 'start') return 'TextAlign.left'
  return null
}

function isInlineTextTag(tag) {
  return tag === 'span' || tag === 'p'
}

function mergeTextStyles(baseStyle, ownStyle) {
  if (baseStyle && ownStyle) return `(${baseStyle}).merge(${ownStyle})`
  return ownStyle || baseStyle || null
}

function buildInlineTextSpans(el, cssMap, topClassName, skipRootDecoration, inheritedStyle = null) {
  const className = getClassNameAttr(el)
  const props = className && cssMap[className] ? cssMap[className] : {}
  const style = mergeTextStyles(inheritedStyle, textStyleFromProps(props))
  const spans = []
  for (const c of el.children || []) {
    if (isTextNode(c)) {
      const text = c.value.trim()
      if (!text) continue
      const parts = [`text: ${toDartLiteral(text)}`]
      if (style) parts.push(`style: ${style}`)
      spans.push(`TextSpan(${parts.join(', ')})`)
      continue
    }
    if (c.type !== 'JSXElement') continue
    const childTag = jsxElementName(c).toLowerCase()
    if (childTag === 'br') {
      const parts = [`text: '\\n'`]
      if (style) parts.push(`style: ${style}`)
      spans.push(`TextSpan(${parts.join(', ')})`)
      continue
    }
    if (isInlineTextTag(childTag)) {
      spans.push(...buildInlineTextSpans(c, cssMap, topClassName, skipRootDecoration, style))
      continue
    }
    const child = buildWidgetFromElement(c, cssMap, topClassName, skipRootDecoration)
    spans.push(`WidgetSpan(child: ${child.widget})`)
  }
  return spans
}

function paddingFromProps(props) {
  const p = props['padding']
  const pt = props['padding-top']
  const pr = props['padding-right']
  const pb = props['padding-bottom']
  const pl = props['padding-left']
  if (p) {
    const box = parseBoxValues(p)
    if (box) return `EdgeInsets.fromLTRB(${box.left}, ${box.top}, ${box.right}, ${box.bottom})`
    const v = cssPxToDouble(p)
    if (v !== null) return `EdgeInsets.all(${v})`
  }
  const top = cssPxToDouble(pt) || 0
  const right = cssPxToDouble(pr) || 0
  const bottom = cssPxToDouble(pb) || 0
  const left = cssPxToDouble(pl) || 0
  if (top || right || bottom || left) return `EdgeInsets.fromLTRB(${left}, ${top}, ${right}, ${bottom})`
  return null
}

function borderRadiusFromProps(props) {
  const v = props['border-radius']
  const box = parseBoxValues(v)
  if (box) {
    if (box.top === box.right && box.top === box.bottom && box.top === box.left) {
      return `BorderRadius.circular(${box.top})`
    }
    return `BorderRadius.only(topLeft: Radius.circular(${box.top}), topRight: Radius.circular(${box.right}), bottomRight: Radius.circular(${box.bottom}), bottomLeft: Radius.circular(${box.left}))`
  }
  const n = cssPxToDouble(v)
  if (n !== null) return `BorderRadius.circular(${n})`
  return null
}

function marginFromProps(props) {
  const m = props['margin']
  const mt = props['margin-top']
  const mr = props['margin-right']
  const mb = props['margin-bottom']
  const ml = props['margin-left']
  if (m) {
    const box = parseBoxValues(m)
    if (box) return `EdgeInsets.fromLTRB(${box.left}, ${box.top}, ${box.right}, ${box.bottom})`
    const v = cssPxToDouble(m)
    if (v !== null) return `EdgeInsets.all(${v})`
  }
  const top = cssPxToDouble(mt) || 0
  const right = cssPxToDouble(mr) || 0
  const bottom = cssPxToDouble(mb) || 0
  const left = cssPxToDouble(ml) || 0
  if (top || right || bottom || left) return `EdgeInsets.fromLTRB(${left}, ${top}, ${right}, ${bottom})`
  return null
}

function borderFromProps(props) {
  const border = props['border']
  const borderWidth = props['border-width']
  const borderColor = props['border-color']
  let width = borderWidth ? cssPxToDouble(borderWidth) : null
  let color = borderColor ? cssColorToAppColor(borderColor) : null
  if (border) {
    if (width == null) {
      const m = String(border).match(/(-?\d*\.?\d+)px/)
      if (m) width = parseFloat(m[1])
    }
    if (!color) {
      const colorMatch = String(border).match(/(rgba?\([^)]*\)|#[0-9a-f]{3,8}|var\([^)]*\))/i)
      if (colorMatch) color = cssColorToAppColor(colorMatch[1])
    }
  }
  if (width == null && !color) return null
  if (width == null) width = 1
  if (!color) color = 'AppColors.black'
  return `Border.all(color: ${color}, width: ${width})`
}

function borderColorFromProps(props) {
  if (!props) return null
  const border = props['border']
  const borderColor = props['border-color']
  let color = borderColor ? cssColorToAppColor(borderColor) : null
  if (!color && border) {
    const colorMatch = String(border).match(/(rgba?\([^)]*\)|#[0-9a-f]{3,8}|var\([^)]*\))/i)
    if (colorMatch) color = cssColorToAppColor(colorMatch[1])
  }
  return color
}

function boxShadowFromProps(props) {
  const shadow = props['box-shadow']
  if (!shadow) return null
  const parts = String(shadow).split(/,(?![^(]*\))/).map(s => s.trim()).filter(Boolean)
  const shadows = []
  for (const part of parts) {
    const colorMatch = part.match(/(rgba?\([^)]*\)|#[0-9a-f]{3,8}|var\([^)]*\))/i)
    const color = colorMatch ? cssColorToAppColor(colorMatch[1]) : null
    const numbers = part.replace(colorMatch ? colorMatch[1] : '', '').trim().split(/\s+/).filter(Boolean)
    const ox = cssPxToDouble(numbers[0]) ?? 0
    const oy = cssPxToDouble(numbers[1]) ?? 0
    const blur = cssPxToDouble(numbers[2]) ?? 0
    const spread = cssPxToDouble(numbers[3]) ?? 0
    if (!color) continue
    shadows.push(`BoxShadow(offset: Offset(${ox}, ${oy}), blurRadius: ${blur}, spreadRadius: ${spread}, color: ${color})`)
  }
  if (!shadows.length) return null
  return shadows.join(', ')
}

function boxDecorationFromProps(props, options = {}) {
  const { omitBackgroundColor = false } = options
  const bg = props['background'] || props['background-color']
  const bgImg = props['background-image'] || props['backgroundImage']
  const bgGradientSource = bg && /linear-gradient/i.test(bg) ? bg : null
  const gradientSource = bgImg || bgGradientSource
  const gradient = gradientSource && /linear-gradient/i.test(gradientSource)
    ? (parseLinearGradient(gradientSource) || 'AppColors.primaryBackgroundGradient()')
    : null
  const color = bg && !bgGradientSource ? cssColorToAppColor(bg) : null
  const radius = borderRadiusFromProps(props)
  const border = borderFromProps(props)
  const shadows = boxShadowFromProps(props)
  const parts = []
  if (color && !omitBackgroundColor) parts.push(`color: ${color}`)
  if (gradient) parts.push(`gradient: ${gradient}`)
  if (radius) parts.push(`borderRadius: ${radius}`)
  if (border) parts.push(`border: ${border}`)
  if (shadows) parts.push(`boxShadow: [${shadows}]`)
  return parts.length ? `BoxDecoration(${parts.join(', ')})` : null
}

function usesAppOwnedInputBackground(widget) {
  if (!widget) return false
  const normalized = String(widget).trim()
  return normalized.startsWith('AppInput(') || normalized.startsWith('_GeneratedDateTimeField(')
}

function toDartLiteral(s) {
  const t = String(s || '')
  return `'${t.replace(/\\/g, '\\\\').replace(/\$/g, '\\$').replace(/'/g, "\\'")}'`
}

function isTextNode(node) {
  return node.type === 'JSXText'
}

function jsxElementName(el) {
  const n = el.openingElement.name
  if (n.type === 'JSXIdentifier') return n.name
  return 'div'
}

function getClassNameAttr(el) {
  const attrs = el.openingElement.attributes || []
  for (const a of attrs) {
    if (a.type === 'JSXAttribute' && a.name && a.name.name === 'className') {
      if (a.value && a.value.type === 'StringLiteral') return a.value.value
      if (a.value && a.value.type === 'JSXExpressionContainer') {
        const expr = a.value.expression
        if (expr.type === 'StringLiteral') return expr.value
        if (expr.type === 'MemberExpression') {
          const obj = expr.object
          const prop = expr.property
          if ((obj.type === 'Identifier' && obj.name === 'styles') && prop.type === 'Identifier') {
            return prop.name
          }
        }
      }
    }
  }
  return null
}

function assetForClassName(className) {
  if (!className) return null
  if (ICONS_MAP[className]) return ICONS_MAP[className]
  const n = className.toLowerCase()
  const map = [
    { key: 'calendar', asset: 'AppAssets.iconsCalendarSvg' },
    { key: 'search', asset: 'AppAssets.iconsSearchSvg' },
    { key: 'user', asset: 'AppAssets.iconsUserSvg' },
    { key: 'key', asset: 'AppAssets.iconsUserKeySvg' },
    { key: 'family', asset: 'AppAssets.iconsFamilySvg' },
    { key: 'phone', asset: 'AppAssets.iconsPhoneSvg' },
    { key: 'location', asset: 'AppAssets.iconsLocationSvg' },
    { key: 'battery', asset: 'AppAssets.iconsBatterySvg' },
    { key: 'solar', asset: 'AppAssets.iconsSolarSvg' },
    { key: 'water', asset: 'AppAssets.iconsWaterSystemSvg' },
    { key: 'home', asset: 'AppAssets.iconsHomeSvg' },
    { key: 'notification', asset: 'AppAssets.iconsNotificationSvg' },
    { key: 'percent', asset: 'AppAssets.iconsPercentSvg' },
    { key: 'plus', asset: 'AppAssets.iconsPlusSvg' },
  ]
  for (const m of map) {
    if (n.includes(m.key)) return m.asset
  }
  return null
}

function sizeFromProps(props) {
  const w = cssPxToDouble(props['width'])
  const h = cssPxToDouble(props['height'])
  return { w, h }
}

function positionFromProps(props) {
  const pos = (props['position'] || '').toLowerCase()
  if (pos !== 'absolute') return null
  const top = cssPxToDouble(props['top'])
  const left = cssPxToDouble(props['left'])
  const right = cssPxToDouble(props['right'])
  const bottom = cssPxToDouble(props['bottom'])
  if (top == null && left == null && right == null && bottom == null) return null
  return { top, left, right, bottom }
}

function zIndexFromProps(props) {
  const raw = props['z-index']
  const n = raw == null ? NaN : parseInt(raw, 10)
  return Number.isFinite(n) ? n : 0
}

function flexGrowFromProps(props) {
  const raw = props['flex-grow'] ?? props['flex']
  if (raw == null) return 0
  const m = String(raw).trim().match(/-?\d+(\.\d+)?/)
  if (!m) return 0
  const n = parseFloat(m[0])
  return Number.isFinite(n) ? n : 0
}

function rotationFromProps(props) {
  const raw = props['rotate'] || props['transform']
  if (!raw) return null
  const m = String(raw).match(/(-?\d+(\.\d+)?)deg/i)
  if (!m) return null
  const deg = parseFloat(m[1])
  if (!Number.isFinite(deg)) return null
  return deg * Math.PI / 180
}

function estimateStackSize(absKids) {
  let maxRight = 0
  let maxBottom = 0
  for (const child of absKids) {
    const pos = child.position || {}
    const w = child.size?.w ?? 0
    const h = child.size?.h ?? 0
    const left = pos.left ?? 0
    const top = pos.top ?? 0
    const rightEdge = (pos.left != null ? left : (pos.right != null ? pos.right : 0)) + w
    const bottomEdge = (pos.top != null ? top : (pos.bottom != null ? pos.bottom : 0)) + h
    if (rightEdge > maxRight) maxRight = rightEdge
    if (bottomEdge > maxBottom) maxBottom = bottomEdge
  }
  const width = maxRight > 0 ? maxRight : null
  const height = maxBottom > 0 ? maxBottom : null
  if (width == null && height == null) return null
  return { w: width, h: height }
}

function flexConfigFromProps(props) {
  if ((props['display'] || '').includes('flex')) {
    // CSS default is `row` when `flex-direction` is omitted.
    const dir = (props['flex-direction'] || 'row').toLowerCase()
    const align = (props['align-items'] || '').toLowerCase()
    const justify = (props['justify-content'] || '').toLowerCase()
    const gapCol = cssPxToDouble(props['column-gap'])
    const gapRow = cssPxToDouble(props['row-gap'])
    const isRow = dir.includes('row')
    const main = (() => {
      switch (justify) {
        case 'center': return 'MainAxisAlignment.center'
        case 'space-between': return 'MainAxisAlignment.spaceBetween'
        case 'space-around': return 'MainAxisAlignment.spaceAround'
        case 'flex-end': return 'MainAxisAlignment.end'
        default: return 'MainAxisAlignment.start'
      }
    })()
    const cross = (() => {
      switch (align) {
        case 'center': return 'CrossAxisAlignment.center'
        case 'flex-end': return 'CrossAxisAlignment.end'
        case 'stretch': return 'CrossAxisAlignment.stretch'
        default: return 'CrossAxisAlignment.start'
      }
    })()
    return { isRow, main, cross, gap: isRow ? gapCol : gapRow }
  }
  return null
}

function getAttr(el, name) {
  const attrs = el.openingElement.attributes || []
  for (const a of attrs) {
    if (a.type === 'JSXAttribute' && a.name && a.name.name === name) {
      if (a.value && a.value.type === 'StringLiteral') return a.value.value
    }
  }
  return null
}

function normalizeTextValue(raw) {
  return String(raw || '').replace(/\s+/g, ' ').trim()
}

function extractTextsFromElement(el, out = []) {
  if (!el || !el.children) return out
  for (const child of el.children) {
    if (child.type === 'JSXText') {
      const text = normalizeTextValue(child.value)
      if (text) out.push(text)
      continue
    }
    if (child.type === 'JSXExpressionContainer' && child.expression?.type === 'StringLiteral') {
      const text = normalizeTextValue(child.expression.value)
      if (text) out.push(text)
      continue
    }
    if (child.type === 'JSXElement') {
      extractTextsFromElement(child, out)
    }
  }
  return out
}

function uniqueTexts(texts) {
  const result = []
  const seen = new Set()
  for (const t of texts) {
    const key = normalizeTextValue(t)
    if (!key || seen.has(key)) continue
    seen.add(key)
    result.push(key)
  }
  return result
}

function isHintLikeText(text) {
  const raw = normalizeTextValue(text)
  if (!raw) return false
  if (/^\d[\d\s./:-]*$/.test(raw)) return true
  if (/^(yyyy|yy|mm|dd)/i.test(raw)) return true
  if (raw.includes('YYYY') || raw.includes('MM') || raw.includes('DD')) return true
  if (raw.length >= 24) return true
  return false
}

function deriveInputLabelHint(el) {
  const texts = uniqueTexts(extractTextsFromElement(el, []))
  if (!texts.length) return { label: null, hint: null }
  const labelCandidate = texts.find(t => !isHintLikeText(t)) || texts[0]
  const hintCandidate = texts.find(t => t !== labelCandidate) || null
  return { label: labelCandidate || null, hint: hintCandidate || null }
}

function looksLikeDateText(rawValue) {
  const raw = normalizeTextValue(rawValue)
  if (!raw) return false
  const lower = raw.toLowerCase()
  if (raw.includes('生年')) return true
  if (raw.includes('生年月日')) return true
  if (raw.includes('誕生日')) return true
  if (raw.includes('出生')) return true
  if (raw.includes('設置年')) return true
  if (raw.includes('施工年')) return true
  if (raw.includes('実施年')) return true
  if (raw.includes('年度')) return true
  if (/\bdob\b/.test(lower)) return true
  if (lower.includes('birth')) return true
  if (/(yyyy|yy).*(mm).*(dd)/i.test(raw)) return true
  if (/\b\d{4}[\/.-]\d{1,2}[\/.-]\d{1,2}\b/.test(raw)) return true
  if (/\d{4}年\d{1,2}月\d{1,2}日/.test(raw)) return true
  if (raw.includes('年月日')) return true
  if (raw.includes('日付')) return true
  if (/\bdate\b/.test(lower)) return true
  if (raw.includes('カレンダー')) return true
  if (lower.includes('calendar')) return true
  if (raw.includes('日程')) return true
  const hasYear = raw.includes('年')
  const hasMonth = raw.includes('月')
  const hasDay = raw.includes('日')
  if (hasYear && hasMonth && hasDay) return true
  if (hasMonth && hasDay) return true
  return false
}

function looksLikeDateField({ className, inputType, label, hint }) {
  if (inputType === 'date' || inputType === 'datetime-local' || inputType === 'month') return true
  return [className, label, hint].some(value => looksLikeDateText(value))
}

function extractSvgAssetCall(widget) {
  if (!widget) return null
  const match = String(widget).match(/SvgPicture\.asset\([^)]*\)/)
  return match ? match[0] : null
}

function isSmallIconSize(size) {
  if (!size) return false
  const hasWidth = size.w != null
  const hasHeight = size.h != null
  if (!hasWidth && !hasHeight) return false
  const widthOk = !hasWidth || size.w <= 128
  const heightOk = !hasHeight || size.h <= 128
  return widthOk && heightOk
}

function normalizeGeneratedSize(size) {
  if (!size) return size
  if (isSmallIconSize(size)) return size
  if (size.h != null && size.h > 1200) {
    return { ...size, h: null }
  }
  return size
}

function simplifySvgWidget(widget, size) {
  const svgCall = extractSvgAssetCall(widget)
  if (!svgCall) return null
  if (!size || (size.w == null && size.h == null)) return svgCall
  const width = size.w != null ? `width: ${size.w}, ` : ''
  const height = size.h != null ? `height: ${size.h}, ` : ''
  return `SizedBox(${width}${height}child: ${svgCall})`
}

function applySizeToWidget(widget, size) {
  if (!size || (size.w == null && size.h == null)) return widget
  const width = size.w != null ? `width: ${size.w}, ` : ''
  const height = size.h != null ? `height: ${size.h}, ` : ''
  return `SizedBox(${width}${height}child: ${widget})`
}

function shouldStripIconPositioning(size, position, rotate) {
  return (position != null || rotate != null) && isSmallIconSize(size)
}

function looksLikeInputClass(className) {
  if (!className) return false
  const normalized = String(className).toLowerCase()
  return normalized.includes('textfield')
    || normalized.includes('input')
    || normalized.includes('textarea')
    || normalized.includes('formfield')
    || normalized.includes('form_field')
}

function looksLikeButtonClass(className) {
  if (!className) return false
  const normalized = String(className).toLowerCase()
  return normalized.includes('nextbutton')
    || /(^|[-_])button([0-9]|$|[-_])/.test(normalized)
    || normalized.endsWith('btn')
    || normalized.includes('btn_')
}

function isCheckboxClassName(className) {
  if (!className) return false
  const normalized = String(className).toLowerCase()
  return normalized.includes('checkbox') || normalized.includes('check_box')
}

function isUncheckedCheckboxClass(className) {
  if (!className) return false
  const normalized = String(className).toLowerCase()
  return normalized.includes('checkbox2')
    || normalized.includes('unchecked')
    || normalized.includes('uncheck')
}

function buildCheckboxWidgetFromElement(el, cssMap) {
  if (!el || !Array.isArray(el.children)) return null
  const directElements = el.children.filter(c => c.type === 'JSXElement')
  if (directElements.length < 2 || directElements.length > 3) return null
  const checkboxNode = directElements.find(child => isCheckboxClassName(getClassNameAttr(child)))
  if (!checkboxNode) return null
  const label = uniqueTexts(extractTextsFromElement(el, [])).find(Boolean)
  if (!label) return null
  const checkboxClass = getClassNameAttr(checkboxNode)
  const initialChecked = !isUncheckedCheckboxClass(checkboxClass)
  const checkboxProps = (checkboxClass && cssMap && cssMap[checkboxClass]) ? cssMap[checkboxClass] : {}
  const borderColor = borderColorFromProps(checkboxProps)
  const widgetArgs = [
    `title: ${toDartLiteral(label)}`,
    `initialChecked: ${initialChecked ? 'true' : 'false'}`
  ]
  if (borderColor) widgetArgs.push(`borderColor: ${borderColor}`)
  return `_GeneratedCheckbox(${widgetArgs.join(', ')})`
}

function isRadioClassName(className) {
  if (!className) return false
  const normalized = String(className).toLowerCase()
  return /^radio\d*$/.test(normalized)
    || /(^|[-_])radio\d*($|[-_])/.test(normalized)
    || normalized.includes('radiobutton')
    || normalized.includes('radio_button')
    || normalized.includes('radio-option')
    || normalized.includes('radiooption')
}

function findRadioClassInTree(el) {
  if (!el || el.type !== 'JSXElement') return null
  const cls = getClassNameAttr(el)
  if (isRadioClassName(cls)) return cls
  for (const child of el.children || []) {
    if (child.type !== 'JSXElement') continue
    const match = findRadioClassInTree(child)
    if (match) return match
  }
  return null
}

function extractRadioOptionFromElement(el, cssMap) {
  if (!el || el.type !== 'JSXElement') return null
  const radioClass = findRadioClassInTree(el)
  if (!radioClass) return null
  const texts = uniqueTexts(extractTextsFromElement(el, []))
  const label = texts.find(Boolean)
  if (!label) return null
  const radioProps = (radioClass && cssMap && cssMap[radioClass]) ? cssMap[radioClass] : {}
  const borderColor = borderColorFromProps(radioProps)
  const normalizedRadio = radioClass.toLowerCase()
  const selected = normalizedRadio === 'radio2' || normalizedRadio === 'radio3' || normalizedRadio.includes('checked')
  return { label, selected, borderColor }
}

function buildRadioGroupWidgetFromElement(el, cssMap) {
  if (!el || !Array.isArray(el.children)) return null
  const directElements = el.children.filter(c => c.type === 'JSXElement')
  if (directElements.length < 2) return null
  const options = []
  for (const child of directElements) {
    const option = extractRadioOptionFromElement(child, cssMap)
    if (!option) return null
    options.push(option)
  }
  if (options.length < 2) return null
  const optionLiterals = options.map(option => {
    const valueLiteral = toDartLiteral(option.label)
    const labelLiteral = toDartLiteral(option.label)
    return `AppRadioOption(value: ${valueLiteral}, label: ${labelLiteral})`
  })
  const selected = options.find(o => o.selected) || options[0]
  const inactive = options.find(o => !o.selected && o.borderColor)
  const widgetArgs = [
    `initialValue: ${toDartLiteral(selected.label)}`,
    `options: [${optionLiterals.join(', ')}]`
  ]
  if (selected.borderColor) widgetArgs.push(`activeColor: ${selected.borderColor}`)
  if (inactive?.borderColor) widgetArgs.push(`inactiveColor: ${inactive.borderColor}`)
  return `_GeneratedRadioGroup(${widgetArgs.join(', ')})`
}

function wrapOverflowIfSized(body, size) {
  if (process.env.JSX2FLUTTER_ENABLE_OVERFLOW !== '1') return body
  if (!size || (!size.w && !size.h)) return body
  const trimmed = body.trim()
  const isColumn = trimmed.startsWith('Column(')
  const isRow = trimmed.startsWith('Row(')
  if (!isColumn && !isRow) return body
  if (/\b(?:Expanded|Flexible|Spacer)\s*\(/.test(trimmed)) return body
  if (trimmed.includes('SvgPicture.asset(')) return body

  // Only allow overflow on the main axis of the flex container:
  // - Column: vertical overflow
  // - Row: horizontal overflow
  //
  // To keep constraints valid, only apply overflow when the cross-axis size is known.
  // Otherwise, OverflowBox defaults can make the cross-axis unbounded and produce NaN during paint.
  const overflowWidth = isRow && size.w != null && size.h != null
  const overflowHeight = isColumn && size.h != null && size.w != null
  if (!overflowWidth && !overflowHeight) return body

  const overflowArgs = [
    'alignment: Alignment.topLeft',
    'minWidth: 0',
    'minHeight: 0',
  ]
  overflowArgs.push(`maxWidth: ${overflowWidth ? 'double.infinity' : size.w}`)
  overflowArgs.push(`maxHeight: ${overflowHeight ? 'double.infinity' : size.h}`)
  return `OverflowBox(${overflowArgs.join(', ')}, child: ${body})`
}

function unwrapDirectFlexWidget(widgetExpr) {
  let current = String(widgetExpr || '').trim()
  while (/^(?:const\s+)?(?:Expanded|Flexible)\s*\(/.test(current)) {
    const wrapperMatch = current.match(/^(?:const\s+)?(?:Expanded|Flexible)\s*\(([\s\S]*)\)$/)
    if (!wrapperMatch) break
    const childMatch = wrapperMatch[1].match(/\bchild:\s*([\s\S]+)$/)
    if (!childMatch) break
    current = childMatch[1].trim()
  }
  return current
}

function buildGeneratedRippleButton(titleExpr) {
  return `RippleButton(title: ${titleExpr}, backgroundColor: Colors.transparent,minWidth : 0, padding: EdgeInsets.zero, onTap: () {})`
}

function buildWidgetFromElement(el, cssMap, topClassName, skipRootDecoration) {
  const tag = jsxElementName(el).toLowerCase()
  const className = getClassNameAttr(el)
  const props = className && cssMap[className] ? cssMap[className] : {}
  let size = sizeFromProps(props)
  size = normalizeGeneratedSize(size)
  const position = positionFromProps(props)
  const zIndex = zIndexFromProps(props)
  const flexGrow = flexGrowFromProps(props)
  const rotate = rotationFromProps(props)
  const overflowHidden = (props['overflow'] || '').toLowerCase() === 'hidden'
  const inputType = (getAttr(el, 'type') || '').toLowerCase()
  const inputPlaceholder = getAttr(el, 'placeholder')
  const inputLabel = getAttr(el, 'label')
  const inputValue = getAttr(el, 'value')
  let semanticWidget = null
  if (tag === 'input' || tag === 'textarea' || (tag === 'div' && looksLikeInputClass(className))) {
    if (inputType === 'radio') {
      const radioLabel = inputLabel || inputValue || className || 'Option'
      semanticWidget = `_GeneratedRadioGroup(initialValue: ${toDartLiteral(radioLabel)}, options: [AppRadioOption(value: ${toDartLiteral(radioLabel)}, label: ${toDartLiteral(radioLabel)})])`
    } else {
      const derived = deriveInputLabelHint(el)
      const finalLabel = inputLabel || (tag === 'textarea' ? (derived.label || className || '内容') : derived.label)
      const finalHint = inputPlaceholder || inputValue || derived.hint
      const isDateField = tag !== 'textarea' && looksLikeDateField({
        className,
        inputType,
        label: finalLabel,
        hint: finalHint
      })
      const widgetArgs = []
      if (finalLabel) widgetArgs.push(`label: ${toDartLiteral(finalLabel)}`)
      if (finalHint) widgetArgs.push(`hint: ${toDartLiteral(finalHint)}`)
      if (isDateField) {
        semanticWidget = `_GeneratedDateTimeField(${widgetArgs.join(', ')})`
      } else {
        const maxLines = tag === 'textarea' ? 4 : 1
        if (maxLines > 1) widgetArgs.push(`maxLines: ${maxLines}`)
        semanticWidget = `AppInput(${widgetArgs.join(', ')})`
      }
    }
  } else if (tag === 'div') {
    const checkboxWidget = buildCheckboxWidgetFromElement(el, cssMap)
    if (checkboxWidget) {
      semanticWidget = checkboxWidget
    }
    if (!semanticWidget) {
      const radioGroupWidget = buildRadioGroupWidgetFromElement(el, cssMap)
      if (radioGroupWidget) {
        semanticWidget = radioGroupWidget
      }
    }
    if (!semanticWidget && looksLikeButtonClass(className)) {
      const buttonLabel = uniqueTexts(extractTextsFromElement(el, [])).find(Boolean)
      if (buttonLabel) {
        semanticWidget = buildGeneratedRippleButton(toDartLiteral(buttonLabel))
      }
    }
  }
  const children = []
  if (!semanticWidget) {
    for (const c of el.children || []) {
      if (isTextNode(c)) {
        const text = c.value.trim()
        if (text) {
          const style = textStyleFromProps(props)
          const align = textAlignFromProps(props)
          const textLiteral = toDartLiteral(text)
          const gradientText = gradientTextFromProps(props)
          if (gradientText) {
            const parts = [`text: ${textLiteral}`]
            if (style) parts.push(`style: ${style}`)
            if (align) parts.push(`textAlign: ${align}`)
            parts.push(`gradient: ${gradientText}`)
            children.push({ widget: `AppTextGradient(${parts.join(', ')})`, isAbsolute: false, position: null, zIndex: 0, flexGrow: 0, size: { w: null, h: null } })
          } else {
            const parts = [textLiteral]
            if (style) parts.push(`style: ${style}`)
            if (align) parts.push(`textAlign: ${align}`)
            children.push({ widget: `Text(${parts.join(', ')})`, isAbsolute: false, position: null, zIndex: 0, flexGrow: 0, size: { w: null, h: null } })
          }
        }
      } else if (c.type === 'JSXElement') {
        children.push(buildWidgetFromElement(c, cssMap, topClassName, skipRootDecoration))
      }
    }
  }
  if (!semanticWidget && tag !== 'img' && shouldStripIconPositioning(size, position, rotate)) {
    const hasDirectText = (el.children || []).some(child => isTextNode(child) && child.value.trim())
    const flowOnlyChildren = children.filter(child => !child.isAbsolute)
    const hasAbsoluteChildren = children.some(child => child.isAbsolute)
    if (!hasDirectText && !hasAbsoluteChildren && flowOnlyChildren.length === 1) {
      const simplifiedIcon = simplifySvgWidget(flowOnlyChildren[0].widget, size)
      if (simplifiedIcon) {
        return { widget: simplifiedIcon, isAbsolute: false, position: null, zIndex, flexGrow, size }
      }
    }
  }
  if (tag === 'img') {
    const src = getAttr(el, 'src') || ''
    if (/^https?:\/\//.test(src)) {
      const widget = `Image.network(${toDartLiteral(src)}, fit: BoxFit.cover)`
      const sized = applySizeToWidget(widget, size)
      return { widget: rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${sized})` : sized, isAbsolute: !!position, position, zIndex, flexGrow, size }
    }
    const local = resolveLocalAsset(src, className)
    if (local) {
      const widget = local.isSvg
        ? `SvgPicture.asset(${local.assetRef})`
        : `Image.asset(${local.assetRef}, fit: BoxFit.contain)`
      if (local.isSvg) {
        const simplified = simplifySvgWidget(widget, size) || widget
        const stripPlacement = shouldStripIconPositioning(size, position, rotate)
        const finalWidget = (rotate != null && !stripPlacement) ? `Transform.rotate(angle: ${rotate}, child: ${simplified})` : simplified
        return { widget: finalWidget, isAbsolute: stripPlacement ? false : !!position, position: stripPlacement ? null : position, zIndex, flexGrow, size }
      }
      const sized = applySizeToWidget(widget, size)
      return { widget: rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${sized})` : sized, isAbsolute: !!position, position, zIndex, flexGrow, size }
    }
    const asset = assetForClassName(className)
    if (asset) {
      const widget = `SvgPicture.asset(${asset})`
      const simplified = simplifySvgWidget(widget, size) || widget
      const stripPlacement = shouldStripIconPositioning(size, position, rotate)
      const finalWidget = (rotate != null && !stripPlacement) ? `Transform.rotate(angle: ${rotate}, child: ${simplified})` : simplified
      return { widget: finalWidget, isAbsolute: stripPlacement ? false : !!position, position: stripPlacement ? null : position, zIndex, flexGrow, size }
    }
    const widget = 'SizedBox.shrink()'
    return { widget: rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${widget})` : widget, isAbsolute: !!position, position, zIndex, flexGrow, size }
  }
  if (tag === 'button') {
    let labelText = toDartLiteral('Button')
    if (children.length) {
      const m = children[0]?.widget?.match(/Text\('([^']*)'/)
      if (m && m[1]) labelText = `'${m[1]}'`
    }
    const widget = buildGeneratedRippleButton(labelText)
    return { widget: rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${widget})` : widget, isAbsolute: !!position, position, zIndex, flexGrow, size }
  }
  if (tag === 'span' || tag === 'p') {
    const align = textAlignFromProps(props)
    const spans = buildInlineTextSpans(el, cssMap, topClassName, skipRootDecoration)
    const widget = spans.length
      ? `RichText(text: TextSpan(children: [${spans.join(', ')}])${align ? `, textAlign: ${align}` : ''})`
      : 'SizedBox.shrink()'
    return { widget: rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${widget})` : widget, isAbsolute: !!position, position, zIndex, flexGrow, size }
  }
  const padding = paddingFromProps(props)
  const margin = marginFromProps(props)
  const flowKids = semanticWidget ? [] : children.filter(c => !c.isAbsolute)
  const absKids = semanticWidget ? [] : children.filter(c => c.isAbsolute).sort((a, b) => (a.zIndex || 0) - (b.zIndex || 0))
  const inputOwnedWidget = usesAppOwnedInputBackground(semanticWidget)
  const wrappedInputOwnedWidget = !semanticWidget && flowKids.length === 1 && usesAppOwnedInputBackground(flowKids[0].widget)
  const appOwnedInputWidget = inputOwnedWidget || wrappedInputOwnedWidget
  const omitBackgroundColor = appOwnedInputWidget
  const decoration = (skipRootDecoration && className === topClassName)
    ? null
    : boxDecorationFromProps(props, { omitBackgroundColor })
  const effectivePadding = appOwnedInputWidget ? null : padding
  const effectiveDecoration = appOwnedInputWidget ? null : decoration
  const layoutSize = (appOwnedInputWidget && size) ? { ...size, h: null } : size
  const flex = flexConfigFromProps(props)
  let flowBody = semanticWidget
  if (!flowBody && flowKids.length) {
    if (flex) {
      const isScrollableRoot = className === topClassName && process.env.JSX2FLUTTER_MODE !== 'classic'
      const alignSelf = String(props['align-self'] || '').toLowerCase()
      const hasMainAxisSize = !isScrollableRoot && (flex.isRow
        ? (layoutSize.w != null || alignSelf === 'stretch')
        : (layoutSize.h != null))
      const gapLiteral = flex.gap ? (flex.isRow ? `${flex.gap}.width` : `${flex.gap}.height`) : null
      const baseKids = flowKids.map(c => {
        if (flex && c.flexGrow > 0 && hasMainAxisSize) {
          const flexValue = Math.max(1, Math.round(c.flexGrow))
          return `Expanded(flex: ${flexValue}, child: ${c.widget})`
        }
        return c.widget
      })
      const kids = gapLiteral && baseKids.length > 1
        ? baseKids.map((c, i) => i < baseKids.length - 1 ? `${c}, ${gapLiteral}` : c).join(', ')
        : baseKids.join(', ')
      flowBody = flex.isRow
        ? `Row(mainAxisAlignment: ${flex.main}, crossAxisAlignment: ${flex.cross}, children: [${kids}])`
        : `Column(crossAxisAlignment: ${flex.cross}, mainAxisAlignment: ${flex.main}, children: [${kids}])`
    } else if (flowKids.length === 1 && absKids.length === 0) {
      flowBody = flowKids[0].widget
    } else {
      flowBody = `Column(crossAxisAlignment: CrossAxisAlignment.start, children: [${flowKids.map(c => c.widget).join(', ')}])`
    }
  }
  let body = flowBody || 'SizedBox.shrink()'
  if (absKids.length) {
    const stackChildren = []
    let primaryAbsIndex = -1
    if (flowBody) {
      stackChildren.push(flowBody)
    } else {
      for (let i = 0; i < absKids.length; i += 1) {
        const child = absKids[i]
        const pos = child.position || {}
        const isAnchoredTopLeft = (pos.top == null || pos.top === 0)
          && (pos.left == null || pos.left === 0)
          && pos.right == null
          && pos.bottom == null
        if (isAnchoredTopLeft && !isSmallIconSize(child.size)) {
          primaryAbsIndex = i
          stackChildren.push(child.widget)
          break
        }
      }
      if (primaryAbsIndex === -1) {
        const derived = normalizeGeneratedSize(estimateStackSize(absKids))
        const derivedHeight = className === topClassName ? null : derived?.h
        if (derived && (derived.w != null || derivedHeight != null)) {
          const w = derived.w != null ? `width: ${derived.w}, ` : ''
          const h = derivedHeight != null ? `height: ${derivedHeight}, ` : ''
          stackChildren.push(`SizedBox(${w}${h})`)
        }
      }
    }
    for (let i = 0; i < absKids.length; i += 1) {
      if (i === primaryAbsIndex) continue
      const child = absKids[i]
      if (isSmallIconSize(child.size)) {
        const simplifiedIcon = simplifySvgWidget(child.widget, child.size)
        if (simplifiedIcon) {
          stackChildren.push(simplifiedIcon)
          continue
        }
      }
      const pos = child.position || {}
      const args = []
      if (pos.top != null) args.push(`top: ${pos.top}`)
      if (pos.left != null) args.push(`left: ${pos.left}`)
      if (pos.right != null) args.push(`right: ${pos.right}`)
      if (pos.bottom != null) args.push(`bottom: ${pos.bottom}`)
      const positioned = args.length
        ? `Positioned(${args.join(', ')}, child: ${child.widget})`
        : child.widget
      stackChildren.push(positioned)
    }
    body = `Stack(clipBehavior: Clip.none, children: [${stackChildren.join(', ')}])`
  }
  if (effectivePadding || margin || effectiveDecoration) {
    const padLine = effectivePadding ? `padding: ${effectivePadding},` : ''
    const marLine = margin ? `margin: ${margin},` : ''
    const decLine = effectiveDecoration ? `decoration: ${effectiveDecoration},` : ''
    const sizedChild = (layoutSize.w || layoutSize.h) && className !== topClassName
      ? `SizedBox(${layoutSize.w ? `width: ${layoutSize.w}, ` : ''}${layoutSize.h ? `height: ${layoutSize.h}, ` : ''}child: ${wrapOverflowIfSized(body, layoutSize)})`
      : body
    let container = `Container(${padLine}${marLine}${decLine} child: ${sizedChild})`
    if (overflowHidden) {
      const radius = borderRadiusFromProps(props)
      container = radius
        ? `ClipRRect(borderRadius: ${radius}, child: ${container})`
        : `ClipRect(child: ${container})`
    }
    const widget = rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${container})` : container
    return { widget, isAbsolute: !!position, position, zIndex, flexGrow, size: layoutSize }
  }
  if ((layoutSize.w || layoutSize.h) && className !== topClassName) {
    let sized = `SizedBox(${layoutSize.w ? `width: ${layoutSize.w}, ` : ''}${layoutSize.h ? `height: ${layoutSize.h}, ` : ''}child: ${wrapOverflowIfSized(body, layoutSize)})`
    if (overflowHidden) {
      const radius = borderRadiusFromProps(props)
      sized = radius
        ? `ClipRRect(borderRadius: ${radius}, child: ${sized})`
        : `ClipRect(child: ${sized})`
    }
      const widget = rotate != null ? `Transform.rotate(angle: ${rotate}, child: ${sized})` : sized
    return { widget, isAbsolute: !!position, position, zIndex, flexGrow, size: layoutSize }
  }
  let finalWidget = body
  if (overflowHidden) {
    const radius = borderRadiusFromProps(props)
    finalWidget = radius
      ? `ClipRRect(borderRadius: ${radius}, child: ${finalWidget})`
      : `ClipRect(child: ${finalWidget})`
  }
  if (rotate != null) finalWidget = `Transform.rotate(angle: ${rotate}, child: ${finalWidget})`
  return { widget: finalWidget, isAbsolute: !!position, position, zIndex, flexGrow, size: layoutSize }
}

function generateDart(ast, cssMap, outClassName, outPath) {
  let rootWidget = null
  let topClassName = null
  traverse(ast, {
    JSXElement(pathNode) {
      if (!rootWidget) {
        topClassName = getClassNameAttr(pathNode.node)
        const mode = process.env.JSX2FLUTTER_MODE
        rootWidget = buildWidgetFromElement(pathNode.node, cssMap, topClassName, mode !== 'classic')
      }
    }
  })
  // Root wrapper: background + scroll
  const rootProps = topClassName && cssMap[topClassName] ? cssMap[topClassName] : {}
  const rootSize = sizeFromProps(rootProps)
  const rootWidth = rootSize.w
  const rootDeco = boxDecorationFromProps(rootProps)
  const mode = process.env.JSX2FLUTTER_MODE
  let inner = rootWidget?.widget || 'const SizedBox.shrink()'
  inner = unwrapDirectFlexWidget(inner)
  let finalRoot
  if (mode === 'classic') {
    finalRoot = inner
  } else if (mode === 'scaffold') {
    finalRoot = rootDeco
      ? `Scaffold(body: Container(width: Get.width, decoration: ${rootDeco}, child: SingleChildScrollView(child: ${inner})))`
      : `Scaffold(body: Container(width: Get.width, child: SingleChildScrollView(child: ${inner})))`
  } else {
    finalRoot = rootDeco
      ? `DecoratedBox(decoration: ${rootDeco}, child: SingleChildScrollView(child: FittedBox(alignment: Alignment.topLeft, fit: BoxFit.fitWidth, child: ${inner})))`
      : `SingleChildScrollView(child: FittedBox(alignment: Alignment.topLeft, fit: BoxFit.fitWidth, child: ${inner}))`
  }
  if (rootWidth != null) {
    const numericRootWidth = Number(rootWidth)
    const escapedRootWidth = String(rootWidth).replace('.', '\\.')
    const rootWidthPattern = Number.isInteger(numericRootWidth) ? `${escapedRootWidth}(?:\\.0+)?` : escapedRootWidth
    finalRoot = finalRoot.replace(new RegExp(`width:\\s*${rootWidthPattern}(?=\\s*[,\\)])`, 'g'), 'width: Get.width')
    finalRoot = finalRoot.replace(new RegExp(`maxWidth:\\s*${rootWidthPattern}(?=\\s*[,\\)])`, 'g'), 'maxWidth: Get.width')
  }
  const usesDateTimeField = finalRoot.includes('_GeneratedDateTimeField(')
  const usesInput = finalRoot.includes('AppInput(')
  const usesRadio = finalRoot.includes('_GeneratedRadioGroup(') || finalRoot.includes('AppRadioGroup(') || finalRoot.includes('AppRadioOption(')
  const usesCheckbox = finalRoot.includes('_GeneratedCheckbox(') || finalRoot.includes('AppCheckbox(')
  const usesRippleButton = finalRoot.includes('RippleButton(')
  const usesTextGradient = finalRoot.includes('AppTextGradient(')
  const usesGetWidth = finalRoot.includes('Get.width')
  const imports = [
    "import 'package:flutter/material.dart';",
    "import 'package:link_home/src/utils/app_colors.dart';",
    "import 'package:link_home/src/extensions/int_extensions.dart';",
    "import 'package:flutter_svg/flutter_svg.dart';",
    "import 'package:link_home/src/utils/app_assets.dart';",
  ]
  if (usesInput) {
    imports.push("import 'package:link_home/src/ui/widgets/app_input.dart';")
  }
  if (usesDateTimeField) {
    imports.push("import 'package:link_home/src/ui/widgets/app_input_full_time.dart';")
  }
  if (usesRadio) {
    imports.push("import 'package:link_home/src/ui/widgets/app_radio_button.dart';")
  }
  if (usesCheckbox) {
    imports.push("import 'package:link_home/src/ui/widgets/base/checkbox/app_checkbox.dart';")
  }
  if (usesRippleButton) {
    imports.push("import 'package:link_home/src/ui/widgets/base/ripple_button.dart';")
  }
  if (usesTextGradient) {
    imports.push("import 'package:link_home/src/ui/widgets/app_text_gradient.dart';")
  }
  if (usesGetWidth) {
    imports.push("import 'package:get/get.dart';")
  }
  const helperBlocks = []
  if (usesDateTimeField) {
    helperBlocks.push(
      [
        "class _GeneratedDateTimeField extends StatefulWidget {",
        "  final String? label;",
        "  final String? hint;",
        "  const _GeneratedDateTimeField({this.label, this.hint});",
        "  @override",
        "  State<_GeneratedDateTimeField> createState() => _GeneratedDateTimeFieldState();",
        "}",
        "",
        "class _GeneratedDateTimeFieldState extends State<_GeneratedDateTimeField> {",
        "  late DateTime _selectedDate;",
        "  @override",
        "  void initState() {",
        "    super.initState();",
        "    final parsed = _parseDate(widget.hint);",
        "    _selectedDate = parsed ?? DateTime.now();",
        "  }",
        "  DateTime? _parseDate(String? value) {",
        "    final raw = (value ?? '').trim();",
        "    if (raw.isEmpty) {",
        "      return null;",
        "    }",
        "    final normalized = raw",
        "      .replaceAll('年', '/')",
        "      .replaceAll('月', '/')",
        "      .replaceAll('日', '')",
        "      .replaceAll('.', '/')",
        "      .replaceAll('-', '/');",
        "    final full = RegExp(r'(\\\\d{4})/(\\\\d{1,2})/(\\\\d{1,2})').firstMatch(normalized);",
        "    if (full != null) {",
        "      final year = int.tryParse(full.group(1)!);",
        "      final month = int.tryParse(full.group(2)!);",
        "      final day = int.tryParse(full.group(3)!);",
        "      if (year != null && month != null && day != null) {",
        "        return DateTime(year, month, day);",
        "      }",
        "    }",
        "    final yearMonth = RegExp(r'(\\\\d{4})/(\\\\d{1,2})').firstMatch(normalized);",
        "    if (yearMonth != null) {",
        "      final year = int.tryParse(yearMonth.group(1)!);",
        "      final month = int.tryParse(yearMonth.group(2)!);",
        "      if (year != null && month != null) {",
        "        return DateTime(year, month, 1);",
        "      }",
        "    }",
        "    final yearOnly = RegExp(r'\\\\b(\\\\d{4})\\\\b').firstMatch(normalized);",
        "    if (yearOnly != null) {",
        "      final year = int.tryParse(yearOnly.group(1)!);",
        "      if (year != null) {",
        "        return DateTime(year, 1, 1);",
        "      }",
        "    }",
        "    return null;",
        "  }",
        "  @override",
        "  Widget build(BuildContext context) {",
        "    return AppInputFullTime(",
        "      label: widget.label,",
        "      hint: widget.hint ?? 'YYYY/MM/DD',",
        "      initialTime: _selectedDate,",
        "      onTimeChanged: (next) {",
        "        if (!mounted) {",
        "          return;",
        "        }",
        "        setState(() => _selectedDate = next);",
        "      },",
        "      minimumYear: 1900,",
        "      maximumYear: 2100,",
        "    );",
        "  }",
        "}",
      ].join('\n')
    )
  }
  if (usesRadio) {
    helperBlocks.push(
      [
        "class _GeneratedRadioGroup extends StatefulWidget {",
        "  final String initialValue;",
        "  final List<AppRadioOption> options;",
        "  final Color? activeColor;",
        "  final Color? inactiveColor;",
        "  const _GeneratedRadioGroup({required this.initialValue, required this.options, this.activeColor, this.inactiveColor});",
        "  @override",
        "  State<_GeneratedRadioGroup> createState() => _GeneratedRadioGroupState();",
        "}",
        "",
        "class _GeneratedRadioGroupState extends State<_GeneratedRadioGroup> {",
        "  late String _value;",
        "  @override",
        "  void initState() {",
        "    super.initState();",
        "    if (widget.initialValue.isNotEmpty) {",
        "      _value = widget.initialValue;",
        "    } else if (widget.options.isNotEmpty) {",
        "      _value = widget.options.first.value;",
        "    } else {",
        "      _value = '';",
        "    }",
        "  }",
        "  @override",
        "  Widget build(BuildContext context) {",
        "    if (widget.options.isEmpty) {",
        "      return const SizedBox.shrink();",
        "    }",
        "    return AppRadioGroup(",
        "      value: _value,",
        "      options: widget.options,",
        "      activeColor: widget.activeColor,",
        "      inactiveColor: widget.inactiveColor,",
        "      onChanged: (next) {",
        "        if (!mounted) {",
        "          return;",
        "        }",
        "        setState(() => _value = next);",
        "      },",
        "    );",
        "  }",
        "}",
      ].join('\n')
    )
  }
  if (usesCheckbox) {
    helperBlocks.push(
      [
        "class _GeneratedCheckbox extends StatefulWidget {",
        "  final String title;",
        "  final bool initialChecked;",
        "  final Color? borderColor;",
        "  const _GeneratedCheckbox({required this.title, required this.initialChecked, this.borderColor});",
        "  @override",
        "  State<_GeneratedCheckbox> createState() => _GeneratedCheckboxState();",
        "}",
        "",
        "class _GeneratedCheckboxState extends State<_GeneratedCheckbox> {",
        "  late bool _checked;",
        "  @override",
        "  void initState() {",
        "    super.initState();",
        "    _checked = widget.initialChecked;",
        "  }",
        "  @override",
        "  Widget build(BuildContext context) {",
        "    return AppCheckbox(",
        "      title: widget.title,",
        "      isChecked: _checked,",
        "      borderColor: widget.borderColor,",
        "      onTap: () {",
        "        if (!mounted) {",
        "          return;",
        "        }",
        "        setState(() => _checked = !_checked);",
        "      },",
        "    );",
        "  }",
        "}",
      ].join('\n')
    )
  }
  const content = [
    ...imports,
    "",
    `class ${outClassName} extends StatelessWidget {`,
    "  const " + outClassName + "({super.key});",
    "  @override",
    "  Widget build(BuildContext context) {",
    "    return " + finalRoot + ";",
    "  }",
    "}",
    ...(helperBlocks.length ? ["", ...helperBlocks] : []),
    ""
  ].join('\n')
  writeFile(outPath, content)
}

function run(inJsx, inCss, outDart) {
  const jsx = readFile(inJsx)
  const css = readFile(inCss)
  const assetPrefix = process.env.JSX2FLUTTER_ASSET_PREFIX || ''
  ASSET_CONTEXT = {
    jsxDir: path.dirname(inJsx),
    assetDir: DEFAULT_ASSET_DIR,
    assetPrefix,
    assets: new Map(),
    appAssetsRegistry: loadAppAssetsRegistry(),
    semanticHintByAbs: new Map(),
    fileNameByAbs: new Map(),
    usedFileNames: new Set(),
    copyAssets: process.env.JSX2FLUTTER_COPY_ASSETS !== '0',
    renameAssets: !!sanitizeAssetToken(assetPrefix),
  }
  const cssMap = parseCssModules(css, inCss)
  const ast = parse(jsx, { sourceType: 'module', plugins: ['jsx'] })
  ASSET_CONTEXT.semanticHintByAbs = collectAssetSemanticHints(ast, path.dirname(inJsx))
  const baseName = path.basename(outDart, '.dart')
  const className = toWidgetClassName(baseName)
  generateDart(ast, cssMap, className, outDart)
  copyCollectedAssets()
  syncAppAssetsFile()
}

if (process.argv.length < 5) {
  process.stderr.write('Usage: node jsx2flutter.mjs <index.jsx> <index.module.scss> <out.dart>\\n')
  process.exit(1)
}

run(process.argv[2], process.argv[3], process.argv[4])
