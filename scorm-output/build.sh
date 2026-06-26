#!/usr/bin/env python3
"""
数海漫游 — 一键构建脚本
用法：python3 build.sh
效果：
  1. 重新生成 数海漫游-单文件静态版.html（内联 SCORM API + JSON 数据）
  2. 重新打包 number-sea-explorer-scorm2004.zip
"""
import pathlib, zipfile, json

BASE  = pathlib.Path(__file__).parent / 'number-sea-explorer'
OUT   = pathlib.Path(__file__).parent

# ── 1. 单文件静态版 ────────────────────────────────────────────────────────────
def build_static():
    html         = (BASE / 'index.html').read_text(encoding='utf-8')
    scorm_api    = (BASE / 'scorm-api.js').read_text(encoding='utf-8')
    lesson_json  = (BASE / 'data/lesson.json').read_text(encoding='utf-8')
    questions_json = (BASE / 'data/questions.json').read_text(encoding='utf-8')

    # 去掉外部 scorm-api.js 引用
    html = html.replace('<script src="scorm-api.js"></script>', '')

    # 修改 boot() 读内联 JSON
    old_boot = "    async function boot() {\n      const [lesson, questions] = await Promise.all([fetchJson('data/lesson.json'), fetchJson('data/questions.json')]);\n      Object.assign(state, { lesson, questions, flow: lesson.flow });\n      titleEl.textContent = lesson.title;\n      hydrate();\n      render();\n    }"
    new_boot = """    async function boot() {
      const lesson    = JSON.parse(document.getElementById('lesson-data').textContent);
      const questions = JSON.parse(document.getElementById('questions-data').textContent);
      Object.assign(state, { lesson, questions, flow: lesson.flow });
      titleEl.textContent = lesson.title;
      hydrate();
      render();
    }"""
    if old_boot in html:
        html = html.replace(old_boot, new_boot)
    else:
        idx = html.find('    async function boot() {')
        if idx >= 0:
            end = html.find('\n    }', idx) + 7
            html = html[:idx] + new_boot + html[end:]

    # 设置静态模式标记
    html = html.replace('<body>', '<body data-mode="static">')

    # 修正路径：静态 HTML 在 scorm-output/ 而资源在 number-sea-explorer/
    # 在嵌入前将 JSON 数据中的 assets/ → number-sea-explorer/assets/
    lesson_json    = lesson_json.replace('"assets/', '"number-sea-explorer/assets/')
    questions_json = questions_json.replace('"assets/', '"number-sea-explorer/assets/')

    # 将依赖注入到主 <script> 之前
    inline_deps = f"""  <!-- SCORM API -->
  <script>
{scorm_api}  </script>
  <script type="application/json" id="lesson-data">{lesson_json}</script>
  <script type="application/json" id="questions-data">{questions_json}</script>
"""
    marker = '\n  <script>\n    const app = document.getElementById'
    if marker in html:
        html = html.replace(marker, '\n' + inline_deps + '  <script>\n    const app = document.getElementById')
    else:
        html = html.replace('</body>', inline_deps + '</body>')

    out = OUT / '数海漫游-单文件静态版.html'
    out.write_text(html, encoding='utf-8')
    print(f'  ✅ 单文件静态版  {out.name}  ({out.stat().st_size // 1024} KB)')

# ── 2. SCORM 2004 ZIP ─────────────────────────────────────────────────────────
def build_zip():
    out = OUT / 'number-sea-explorer-scorm2004.zip'
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
        for f in BASE.rglob('*'):
            if f.is_file() and '.DS_Store' not in str(f):
                zf.write(f, str(f.relative_to(BASE)))
    print(f'  ✅ SCORM 2004 包  {out.name}  ({out.stat().st_size // 1024} KB)')

if __name__ == '__main__':
    print('🔨 开始构建数海漫游…')
    build_static()
    build_zip()
    print('🎉 构建完成！')
