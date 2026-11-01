import subprocess, tempfile, pathlib, sys
root = pathlib.Path(__file__).resolve().parents[1]
contents = '\n'.join((root / p).read_text(encoding='utf-8') for p in ('tests/ui_harness_prefix.luau', 'BABFT_AutoBuilder.lua', 'tests/ui_harness_suffix.luau'))
with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', encoding='utf-8') as f:
    f.write(contents); f.flush()
    sys.exit(subprocess.call([sys.argv[1] if len(sys.argv)>1 else 'luau', f.name]))
