import fs from 'node:fs'
import path from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

function exists(p) {
  try { return fs.existsSync(p) } catch { return false }
}

function resolveProjectRoot() {
  const fromCwd = process.cwd()
  if (exists(path.resolve(fromCwd, 'pubspec.yaml'))) {
    return fromCwd
  }
  let current = __dirname
  while (true) {
    if (exists(path.resolve(current, 'pubspec.yaml'))) {
      return current
    }
    const parent = path.dirname(current)
    if (parent === current) break
    current = parent
  }
  return fromCwd
}

function readPackageName(pubspecPath) {
  if (!exists(pubspecPath)) return 'app'
  const content = fs.readFileSync(pubspecPath, 'utf8')
  const matched = content.match(/^name:\s*([A-Za-z0-9_]+)/m)
  return matched?.[1] || 'app'
}

const PROJECT_ROOT = resolveProjectRoot()
const DEFAULT_UI_ROOT = path.resolve(PROJECT_ROOT, 'lib/src/ui')
const PUBSPEC_PATH = path.resolve(PROJECT_ROOT, 'pubspec.yaml')
const PROJECT_PACKAGE_NAME = readPackageName(PUBSPEC_PATH)

function packageImport(relativePath) {
  return `package:${PROJECT_PACKAGE_NAME}/${String(relativePath || '').replace(/^\/+/, '')}`
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true })
}

function toPosixPath(value) {
  return String(value || '').replace(/\\/g, '/')
}

function toSnakeCase(value) {
  const normalized = String(value || '')
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .replace(/[^A-Za-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .toLowerCase()
  return normalized || 'figma_feature'
}

function toPascalCase(value) {
  const snake = toSnakeCase(value)
  return snake
    .split('_')
    .filter(Boolean)
    .map(part => part[0].toUpperCase() + part.slice(1))
    .join('')
}

function classNameFromOutPath(outPath) {
  const baseName = path.basename(outPath, '.dart')
  let className = toPascalCase(baseName)
  if (!/^[A-Za-z_]/.test(className)) {
    className = 'Figma' + className
  }
  return className
}

function parseArgs(rawArgs) {
  const options = {
    feature: null,
    uiRoot: DEFAULT_UI_ROOT,
  }
  const positional = []
  for (let i = 0; i < rawArgs.length; i += 1) {
    const arg = rawArgs[i]
    if (arg === '--feature') {
      options.feature = rawArgs[i + 1] || null
      i += 1
      continue
    }
    if (arg === '--ui-root') {
      const next = rawArgs[i + 1]
      if (next) options.uiRoot = path.resolve(next)
      i += 1
      continue
    }
    positional.push(arg)
  }
  return { options, positional }
}

function resolveFeaturePaths(feature, uiRoot, explicitOut) {
  const featureName = toSnakeCase(feature)
  const featureDir = path.resolve(uiRoot, featureName)
  const componentBase = featureName.endsWith('_figma') ? featureName : `${featureName}_figma`
  const componentFile = `${componentBase}.dart`
  const componentPath = explicitOut
    ? path.resolve(explicitOut)
    : path.resolve(featureDir, 'components', componentFile)
  return {
    featureName,
    featureDir,
    componentPath,
    pagePath: path.resolve(featureDir, `${featureName}_page.dart`),
    bindingPath: path.resolve(featureDir, 'binding', `${featureName}_binding.dart`),
    blocPath: path.resolve(featureDir, 'interactor', `${featureName}_bloc.dart`),
  }
}

function buildPageTemplate(featureName, componentPath) {
  const pageClass = `${toPascalCase(featureName)}Page`
  const componentClass = classNameFromOutPath(componentPath)
  const componentFile = path.basename(componentPath)
  return [
    "import 'package:flutter/material.dart';",
    `import '${packageImport(`src/ui/${featureName}/components/${componentFile}`)}';`,
    '',
    `class ${pageClass} extends StatelessWidget {`,
    `  const ${pageClass}({super.key});`,
    '  @override',
    '  Widget build(BuildContext context) {',
    `    return const ${componentClass}();`,
    '  }',
    '}',
    '',
  ].join('\n')
}

function buildBindingTemplate(featureName) {
  const baseClass = toPascalCase(featureName)
  return [
    "import 'package:get/get.dart';",
    `import '${packageImport(`src/ui/${featureName}/interactor/${featureName}_bloc.dart`)}';`,
    '',
    `class ${baseClass}Binding extends Bindings {`,
    '  @override',
    '  void dependencies() {',
    `    if (Get.isRegistered<${baseClass}Bloc>()) return;`,
    `    Get.lazyPut<${baseClass}Bloc>(() => ${baseClass}Bloc());`,
    '  }',
    '}',
    '',
  ].join('\n')
}

function buildBlocTemplate(featureName) {
  const blocClass = `${toPascalCase(featureName)}Bloc`
  return [
    "import 'package:get/get.dart';",
    '',
    `class ${blocClass} extends GetxController {}`,
    '',
  ].join('\n')
}

function writeIfMissing(filePath, content) {
  if (exists(filePath)) return false
  ensureDir(path.dirname(filePath))
  fs.writeFileSync(filePath, content, 'utf8')
  return true
}

function ensureFeatureStructure(paths) {
  const created = []
  if (writeIfMissing(paths.pagePath, buildPageTemplate(paths.featureName, paths.componentPath))) {
    created.push(paths.pagePath)
  }
  if (writeIfMissing(paths.bindingPath, buildBindingTemplate(paths.featureName))) {
    created.push(paths.bindingPath)
  }
  if (writeIfMissing(paths.blocPath, buildBlocTemplate(paths.featureName))) {
    created.push(paths.blocPath)
  }
  return created
}

function findPairInDir(dir) {
  const jsx = path.resolve(dir, 'index.jsx')
  const scss = path.resolve(dir, 'index.module.scss')
  if (!exists(jsx)) {
    throw new Error(`Không tìm thấy file: ${jsx}`)
  }
  if (!exists(scss)) {
    throw new Error(`Không tìm thấy file: ${scss}`)
  }
  return { jsx, scss }
}

function defaultOutFromJsx(jsxPath) {
  const parent = path.basename(path.dirname(jsxPath))
  let base = parent ? parent.replace(/[^A-Za-z0-9]+/g, '_').toLowerCase() : 'generated_widget'
  if (!/^[A-Za-z_]/.test(base)) {
    base = `figma_${base}`
  }
  const outDir = path.resolve(PROJECT_ROOT, 'tools/output')
  ensureDir(outDir)
  return path.resolve(outDir, `${base}.dart`)
}

function runConverter(jsx, scss, out, envOverrides = {}) {
  ensureDir(path.dirname(out))
  const script = path.resolve(__dirname, 'jsx2flutter.mjs')
  const mode = envOverrides.JSX2FLUTTER_MODE || process.env.JSX2FLUTTER_MODE || 'scaffold'
  const res = spawnSync(process.execPath, [script, jsx, scss, out, 'strict'], {
    stdio: 'inherit',
    env: { ...process.env, JSX2FLUTTER_MODE: mode, ...envOverrides },
  })
  if (res.status !== 0) {
    process.exit(res.status ?? 1)
  }
}

function formatOut(out) {
  const formatCommands = [
    ['dart', ['format', out]],
    ['flutter', ['format', out]],
    ['fvm', ['dart', 'format', out]],
    ['fvm', ['flutter', 'format', out]],
  ]
  for (const [cmd, args] of formatCommands) {
    const res = spawnSync(cmd, args, { stdio: 'inherit' })
    if (res.status === 0) return
  }
}

function ensurePubspecAssetDir(assetDir) {
  if (!exists(PUBSPEC_PATH)) return false
  const normalizedAssetDir = toPosixPath(assetDir).replace(/^\/+|\/+$/g, '')
  if (!normalizedAssetDir) return false
  const entry = `    - ${normalizedAssetDir}/`
  const content = fs.readFileSync(PUBSPEC_PATH, 'utf8')
  const lines = content.split('\n')

  if (lines.some(line => line.trim() === `- ${normalizedAssetDir}/` || line.trim() === `- ${normalizedAssetDir}`)) {
    return false
  }

  const assetsIndex = lines.findIndex(line => line.trim() === 'assets:')
  if (assetsIndex < 0) return false

  let insertAt = assetsIndex + 1
  while (insertAt < lines.length && /^ {4}- /.test(lines[insertAt])) {
    insertAt += 1
  }

  lines.splice(insertAt, 0, entry)
  fs.writeFileSync(PUBSPEC_PATH, lines.join('\n'), 'utf8')
  return true
}

function main() {
  const { options, positional } = parseArgs(process.argv.slice(2))
  if (!options.feature && positional.length === 0) {
    console.error('Cách dùng:')
    console.error('  node convert.mjs <thư_mục_chứa_index.jsx_và_index.module.scss>')
    console.error('  node convert.mjs <path/index.jsx> <path/index.module.scss> [đường_dẫn_output.dart]')
    console.error('  node convert.mjs --feature <ten_tinh_nang> <path/index.jsx> <path/index.module.scss> [component_output.dart]')
    process.exit(1)
  }
  if (options.feature && positional.length < 2) {
    console.error('Thiếu tham số input cho chế độ --feature')
    console.error('Ví dụ: node convert.mjs --feature visit_record ./.figma/399_27379/index.jsx ./.figma/399_27379/index.module.scss')
    process.exit(1)
  }
  if (!options.feature && positional.length === 1) {
    const dir = path.resolve(positional[0])
    const { jsx, scss } = findPairInDir(dir)
    const out = defaultOutFromJsx(jsx)
    runConverter(jsx, scss, out)
    formatOut(out)
    return
  }
  if (options.feature) {
    const jsx = path.resolve(positional[0])
    const scss = path.resolve(positional[1])
    if (!exists(jsx)) throw new Error(`Không tìm thấy: ${jsx}`)
    if (!exists(scss)) throw new Error(`Không tìm thấy: ${scss}`)
    const paths = resolveFeaturePaths(options.feature, options.uiRoot, positional[2])
    const featureAssetPrefix = toSnakeCase(options.feature).replace(/_figma$/, '')
    const assetDir = `assets/figma/${featureAssetPrefix || 'feature'}`
    ensurePubspecAssetDir(assetDir)
    runConverter(jsx, scss, paths.componentPath, {
      JSX2FLUTTER_ASSET_PREFIX: featureAssetPrefix,
      JSX2FLUTTER_ASSET_DIR: assetDir,
    })
    const created = ensureFeatureStructure(paths)
    formatOut(paths.componentPath)
    for (const file of created) {
      formatOut(file)
    }
    return
  }
  if (positional.length >= 2) {
    const jsx = path.resolve(positional[0])
    const scss = path.resolve(positional[1])
    if (!exists(jsx)) throw new Error(`Không tìm thấy: ${jsx}`)
    if (!exists(scss)) throw new Error(`Không tìm thấy: ${scss}`)
    const out = positional[2] ? path.resolve(positional[2]) : defaultOutFromJsx(jsx)
    runConverter(jsx, scss, out)
    formatOut(out)
  }
}

main()
