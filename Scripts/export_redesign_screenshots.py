#!/usr/bin/env python3
"""Build the local screenshot gallery and PR table from XCTest result bundles.

Example:
    python3 Scripts/export_redesign_screenshots.py --output build/redesign-catalog captures.xcresult

Only successful capture tests are imported. For repeated runs, pass every result
bundle; the latest attachment for each named screenshot wins. Nothing is uploaded.
"""
import json, pathlib, re, shutil, html, collections
import argparse, subprocess, tempfile, struct, datetime

parser = argparse.ArgumentParser(description="Export successful RedesignScreenshotTests captures into a local gallery and PR table.")
parser.add_argument("results", nargs="+", type=pathlib.Path, help="One or more .xcresult bundles")
parser.add_argument("--output", required=True, type=pathlib.Path, help="Destination directory (prefer an ignored build/ directory)")
args = parser.parse_args()
ROOT = args.output.resolve()
ROOT.mkdir(parents=True, exist_ok=True)
SHOTS = ROOT / "screenshots"
SHOTS.mkdir(exist_ok=True)
manifest_path = ROOT / "manifest.json"
records = {}
completed_tests = set()

def passed_tests(nodes):
    names = set()
    for node in nodes:
        if node.get("nodeType") == "Test Case" and node.get("result") == "Passed":
            names.add(node["nodeIdentifier"])
        names.update(passed_tests(node.get("children", [])))
    return names

with tempfile.TemporaryDirectory(prefix="mindfulpacer-catalog-") as scratch:
    for index, bundle in enumerate(args.results):
        bundle = bundle.resolve()
        result = json.loads(subprocess.check_output(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(bundle)]))
        passed = passed_tests(result["testNodes"])
        completed_tests.update(passed)
        exported = pathlib.Path(scratch) / str(index)
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle), "--output-path", str(exported)], check=True, stdout=subprocess.DEVNULL)
        for test in json.loads((exported / "manifest.json").read_text()):
            if test["testIdentifier"] not in passed:
                continue
            for attachment in test["attachments"]:
                name = attachment["suggestedHumanReadableName"]
                if not name.startswith("catalog__"):
                    continue
                slug = re.sub(r'_\d+_[A-F0-9-]+\.png$', '', name.removeprefix('catalog__'))
                if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*', slug):
                    raise ValueError(f'Capture name must be a filename-safe slug: {slug!r}')
                path = 'screenshots/' + slug + '.png'
                if path in records and records[path]['timestamp'] > attachment['timestamp']:
                    continue
                shutil.copy2(exported / attachment['exportedFileName'], ROOT / path)
                records[path] = {'file': path, 'id': slug, 'timestamp': attachment['timestamp'],
                                 'test': test['testIdentifier'], 'source': str(bundle)}

if not records:
    parser.error('No catalog__ screenshots from successful tests were found.')
capture_date = datetime.datetime.fromtimestamp(max(x['timestamp'] for x in records.values())).strftime('%d %B %Y')

# Remove only stale captures from the previous generated manifest, never unrelated files.
if manifest_path.exists():
    previous = json.loads(manifest_path.read_text())
    for item in previous.get('screenshots', []):
        if item['file'] not in records:
            path = (ROOT / item['file']).resolve()
            if path.parent == SHOTS.resolve() and path.suffix == '.png':
                path.unlink(missing_ok=True)

def group(slug):
 if 'onboarding' in slug:return 'Onboarding'
 if any(x in slug for x in ['empty-', 'health-fetch-error','health-permission-needed','watch-disconnected']):return 'Empty and recovery states'
 if 'analytics' in slug:return 'Analytics'
 if slug.split('-')[0] in ['01','02','03','04','15'] or '-home-' in slug:return 'Home'
 if 'missed' in slug:return 'Missed reflections'
 if any(x in slug for x in ['outreach','articles','roadmap']):return 'Outreach'
 if any(x in slug for x in ['settings','release-notes']):return 'Settings'
 if 'reminder' in slug:return 'Reminders'
 return 'Reflections'

def title(slug):
 title=re.sub(r'^\d+-','',slug).replace('-',' ')
 title=re.sub(r'\bhr\b', 'heart rate', title).replace(' 1h',' · 1H').replace(' 2h',' · 2H')
 if title.endswith(' w'):title=title[:-2]+' · week'
 if title.endswith(' d'):title=title[:-2]+' · day'
 match=re.match(r'120([0-4])-reminder-(hr|steps)-interval-\d',slug)
 if match:
  metric='Heart rate' if match[2]=='hr' else 'Steps'
  intervals=['1 minute','2 minutes','5 minutes','15 minutes','1 hour'] if match[2]=='hr' else ['30 minutes','1 hour','2 hours','4 hours','1 day']
  return f'Reminder · {metric} · {intervals[int(match[1])]} interval selected'
 match=re.match(r'37[45]([0-5])-reflection-symptom',slug)
 if match:
  symptoms=['Fatigue','Shortness of breath','Sleep disorder','Cognitive impairment','Physical pain','Depression / anxiety']
  return 'Reflection · '+symptoms[int(match[1])]+(' scale explanation' if slug.startswith('375') else ' severity picker')
 match=re.match(r'310([0-3])-onboarding-disable',slug)
 if match:
  return 'Onboarding · '+['Disable stand reminders','Disable activity reminders','Adjust move goals','Disable breathe reminders'][int(match[1])]
 return title[0].upper()+title[1:]

order=['Home','Reflections','Missed reflections','Reminders','Analytics','Outreach','Settings','Onboarding','Empty and recovery states']
items=[]
for path,item in records.items():
 item.update(group=group(item['id']),title=title(item['id']))
 items.append(item)
items.sort(key=lambda x:(order.index(x['group']),x['id']))
manifest={'device':'iPhone 18 Pro','os':'iOS 27 simulator','appearance':'Light','locale':'en_US','dimensions':sorted({struct.unpack('>II', (ROOT / x['file']).read_bytes()[16:24]) for x in items}), 'captureDate':capture_date,
 'data':'Synthetic reflections, reminders, and health history in an in-memory SwiftData container; public MindfulPacer articles fetched by the real app.',
 'scope':'Meaningful screen and selection states, not the Cartesian product of arbitrary field values. No watchOS screenshots.',
 'completedCaptureTests':sorted(completed_tests), 'screenshots':items}
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
counts=collections.Counter(x['group'] for x in items)
options=''.join(f'<option>{html.escape(g)}</option>' for g in order)
cards=''.join(f'''<article data-group="{html.escape(x['group'])}" data-search="{html.escape((x['group']+' '+x['title']).lower())}"><button class="picture" data-index="{i}" aria-label="Open {html.escape(x['title'])}"><img loading="lazy" src="{x['file']}" width="1206" height="2622" alt="{html.escape(x['title'])}"></button><div class="caption"><small>{html.escape(x['group'])}</small><h2>{html.escape(x['title'])}</h2><a href="{x['file']}" download>Original PNG ↗</a></div></article>''' for i,x in enumerate(items))
ROOT.joinpath('index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MindfulPacer · Redesign catalog</title><style>
:root{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#162b29;background:#f1f5f4;font-synthesis:none}*{box-sizing:border-box}body{margin:0}header{padding:46px 5vw 30px;background:linear-gradient(120deg,#e2f2ec,#f7f9fa)}.eyebrow{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#23836c;font-weight:700}h1{font-size:clamp(30px,5vw,58px);letter-spacing:-.04em;margin:10px 0 15px;line-height:1.05}.intro{max-width:720px;line-height:1.6;color:#4c625e}.tags{display:flex;gap:8px;flex-wrap:wrap}.tag{border:1px solid #ceded8;border-radius:99px;padding:7px 12px;font-size:12px;background:#fff8}.toolbar{position:sticky;top:0;z-index:3;display:flex;gap:12px;align-items:center;flex-wrap:wrap;padding:14px 5vw;background:#f7faf9ee;backdrop-filter:blur(16px);border-block:1px solid #dbe5e1}input,select{font:inherit;font-size:14px;border:1px solid #cfdbd6;border-radius:10px;background:white;padding:11px 14px;color:inherit}input{min-width:200px;flex:1;max-width:400px}#count{font-size:13px;color:#5a706a;margin-left:auto}main{padding:28px 5vw 50px;display:grid;grid-template-columns:repeat(auto-fill,minmax(225px,1fr));gap:24px}article{border:1px solid #dce5e1;border-radius:18px;overflow:hidden;background:white;box-shadow:0 4px 15px #10261f04}.picture{display:block;width:100%;padding:16px 16px 0;border:0;background:linear-gradient(#edf1ef,#fff);cursor:zoom-in}.picture img{width:100%;height:auto;display:block;border-radius:12px;border:1px solid #e2e7e4}.caption{padding:16px}small{font-size:10px;text-transform:uppercase;letter-spacing:.08em;color:#33856f;font-weight:700}h2{font-size:14px;line-height:1.4;font-weight:600;min-height:40px;margin:8px 0 12px}a{color:#158369;font-size:12px;text-decoration:none}footer{padding:20px 5vw 45px;font-size:13px;color:#5d716b}dialog{border:0;padding:0;background:transparent;max-width:98vw;max-height:98vh;overflow:visible}dialog::backdrop{background:#09231de8;backdrop-filter:blur(8px)}.viewer{display:flex;align-items:center;gap:18px}.viewer img{height:86vh;width:auto;max-width:80vw;object-fit:contain;border-radius:16px}.viewer button,.close{background:#ffffff22;border:1px solid #ffffff55;color:white;border-radius:50%;width:42px;height:42px;font-size:22px;cursor:pointer}.close{position:absolute;right:-10px;top:-14px;background:#16372d}.legend{color:white;font-size:13px;text-align:center;padding:12px}article[hidden]{display:none}
</style><header><div class="eyebrow">MindfulPacer / iOS redesign</div><h1>The app, screen by screen.</h1><p class="intro">Actual simulator captures with representative synthetic health history, reflections, and reminders. Browse the main screens, editors, selection states, onboarding branches, and recovery states before preparing the redesign PR.</p><div class="tags"><span class="tag">iPhone 18 Pro · iOS 27</span><span class="tag">Light appearance</span><span class="tag">English · '''+capture_date+'''</span><span class="tag">''' +str(len(items))+''' original screenshots</span></div></header><div class="toolbar"><input id="search" type="search" placeholder="Find a screen or selection…" aria-label="Search screenshots"><select id="section" aria-label="Section"><option value="">All sections</option>'''+options+'''</select><a href="PR_TABLE.md">PR table ↗</a><span id="count"></span></div><main>'''+cards+'''</main><footer>Health values and personal entries are synthetic and isolated from personal data. These are unaltered app screenshots, not design mockups. External websites and native system panels are outside this catalog; watchOS and dark appearance were excluded as requested. A screenshot records appearance, not proof of every runtime behavior.</footer><dialog><button class="close" aria-label="Close">×</button><div class="viewer"><button id="prev" aria-label="Previous">‹</button><img alt=""><button id="next" aria-label="Next">›</button></div><div class="legend"></div></dialog><script>
const items='''+json.dumps([{'file':x['file'],'title':x['title']} for x in items])+''';let selected=0;const cards=[...document.querySelectorAll('article')],search=document.querySelector('#search'),section=document.querySelector('#section'),dialog=document.querySelector('dialog');function filter(){let n=0;for(const c of cards){c.hidden=!!((section.value&&c.dataset.group!==section.value)||!c.dataset.search.includes(search.value.toLowerCase()));if(!c.hidden)n++}document.querySelector('#count').textContent=n+' screens'}search.oninput=filter;section.onchange=filter;filter();function show(index){selected=(index+items.length)%items.length;const item=items[selected];dialog.querySelector('img').src=item.file;dialog.querySelector('img').alt=item.title;dialog.querySelector('.legend').textContent=item.title+' · '+(selected+1)+' / '+items.length;if(!dialog.open)dialog.showModal()}document.querySelectorAll('.picture').forEach(b=>b.onclick=()=>show(+b.dataset.index));document.querySelector('.close').onclick=()=>dialog.close();document.querySelector('#prev').onclick=()=>show(selected-1);document.querySelector('#next').onclick=()=>show(selected+1);document.onkeydown=e=>{if(dialog.open&&e.key==='ArrowLeft')show(selected-1);if(dialog.open&&e.key==='ArrowRight')show(selected+1)};dialog.onclick=e=>{if(e.target===dialog)dialog.close()};
</script></html>''')
lines=['# iPhone redesign screenshot catalog','',f'{len(items)} actual iPhone 18 Pro screenshots on iOS 27, in light appearance and English. The app uses isolated synthetic health data, 28 reflections, six reminders, and six missed reflections. Article content comes from the live public MindfulPacer feed.','',
'These files are local PR preparation assets. No PR has been created and no images have been uploaded. When preparing the PR, upload the images or commit the selected assets, then replace the relative image paths below with the resulting GitHub URLs.','',
'## Coverage','', f'{len(completed_tests)} capture flows completed successfully across the supplied result bundles. Failed capture attempts are excluded.', '', '| Area | Captures | Included states |','| --- | ---: | --- |']
desc={'Home':'Today, Reflections, Reminders, recent entries, watch connection warning','Reflections':'Populated and expanded lists, create/edit, activity/subactivity/mood/symptom pickers, filters, deletion','Missed reflections':'All / heart rate / steps, filter menu, selected chart value, accept editor','Reminders':'Both metrics, light/medium/strong, valid intervals, review sheets, locked edit types, deletion','Analytics':'Heart rate and steps × 1H / 2H / day / week, reflection selection, date sheet','Outreach':'Articles, community/resources, article list, roadmap','Settings':'General, appearance, device mode, algorithms, export, erase confirmation, release notes, report','Onboarding':'Phone and Watch setup paths on iPhone, disclosures, complication styles, modes, disclaimer acceptance','Empty and recovery states':'No reflections, no reminders, no health samples, fetch error, permission warning'}
for g in order:lines.append(f'| {g} | {counts[g]} | {desc[g]} |')
highlights=[('Home','01-home-today','15-home-reminders'),('Reflections','11-reflections-list','38-reflection-edit-populated'),('Missed reflections','07-missed-heart-rate','09-missed-steps'),('Reminders','16-reminders-list','122-reminder-hr-review'),('Analytics','20-analytics-hr-1h','27-analytics-steps-w'),('Outreach','220-outreach-articles','221-outreach-community-resources'),('Settings','200-settings-general','205-settings-manage-data'),('Onboarding','304-onboarding-device-phone','313-onboarding-disclaimer')]
lookup={x['id']:x for x in items}
lines+=['','## Main redesign','', '| Area | Primary screen | Supporting screen |','| --- | --- | --- |']
for area,left,right in highlights:
 def thumb(key):
  if key not in lookup:return 'Capture pending'
  x=lookup[key]
  return f'<a href="{x["file"]}"><img src="{x["file"]}" width="220" alt="{x["title"]}"></a>'
 lines.append(f'| {area} | {thumb(left)} | {thumb(right)} |')
lines+=['','## Screenshot tables','', 'Each image opens at its original 1206 × 2622 resolution. Equivalent arbitrary numeric values and every possible cross-product of independent choices are intentionally not duplicated.','']
for g in order:
 subset=[x for x in items if x['group']==g]
 lines += [f'<details><summary>{g} — {len(subset)} captures</summary>','', '| State | Screenshot |','| --- | --- |']
 for x in subset:lines.append(f'| {x["title"]} | <a href="{x["file"]}"><img src="{x["file"]}" width="220" alt="{x["title"]}"></a> |')
 lines+=['','</details>','']
lines+=['## Review observations','', '- Week charts with many reflections currently show crowded activity markers; the captures preserve this for design review.', '- The simulator has no paired Apple Watch, so connection warnings/setup are captured. An actual paired-device connection is not represented.', '- Native permission dialogs, the Files export panel, the Mail composer, and external websites are not included. The debug capture dependencies complete permission requests without changing real HealthKit or notification permissions.', '- The Cancel toolbar item is clipped in some reminder-editor captures; this is preserved for design review.', '- Debug-only controls can appear in Manage Data because these captures run the debug app.','']
ROOT.joinpath('PR_TABLE.md').write_text('\n'.join(lines))
print(f'{len(items)} screenshots; '+', '.join(f'{g}: {counts[g]}' for g in order))
