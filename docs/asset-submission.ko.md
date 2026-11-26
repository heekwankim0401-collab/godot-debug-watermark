# 에셋 등록 기록

Debug Watermark를 Godot 공식 애셋 배포처 두 곳에 올린 값과 순서입니다.
아래 표는 2026-11-26에 실제로 제출한 값입니다. 두 곳 모두 이름과 설명을 영어로 쓰라고
정해 두었으므로, 양식에 넣은 값은 영어이고 설명은 한국어로 적었습니다.

## 제출 상태 (2026-11-26)

| 배포처 | 상태 | 관리 주소 |
| --- | --- | --- |
| 예전 에셋 라이브러리 | 제출함, 모더레이터 검토 대기(번호 25122) | https://godotengine.org/asset-library/asset/edit/25122 |
| 새 에셋 스토어(베타) | 검토 요청함, 상태 "Pending" | https://store.godotengine.org/asset/khkhk/debug-watermark/manage/ |

승인되기 전에는 검색에 나오지 않습니다. 결과는 에셋 라이브러리의 Feed, 스토어의 My Uploads에서
확인합니다.

## 어디에 올리나

| 배포처 | 주소 | 어느 에디터에서 보이나 | 올리는 방식 |
| --- | --- | --- | --- |
| 예전 에셋 라이브러리 | https://godotengine.org/asset-library | Godot 4.0~4.6 에디터의 AssetLib 탭 | GitHub 저장소의 커밋 해시를 적음 |
| 새 에셋 스토어(베타) | https://store.godotengine.org | Godot 4.7 이상 에디터의 Asset Store 탭 | zip 파일을 직접 올림 |

애드온은 Godot 4.2 이상을 지원합니다(4.2.2, 4.6.3, 4.7.2에서 테스트). 그래서 두 곳 모두에
올렸습니다. 예전 라이브러리에 4.2로 등록하면 4.3~4.6 에디터에서도 보입니다.

## 올리기 전에 한 일

1. 이 저장소의 커밋을 GitHub에 푸시했습니다. 아이콘과 미리보기 주소는 푸시한 뒤에야
   열립니다.
2. 푸시한 커밋의 전체 해시를 확인했습니다. 예전 라이브러리의 Download Commit 칸에
   넣습니다.

   ```powershell
   git rev-parse HEAD
   ```

3. 스토어에 올릴 zip을 만들었습니다. `.gitattributes` 설정 때문에 zip에는
   `addons/debug_watermark/`만 들어갑니다(테스트 러너는 빠짐). `dist` 폴더는 git에
   올리지 않으므로 먼저 만듭니다.

   ```powershell
   New-Item -ItemType Directory -Force dist
   ```

   ```powershell
   git archive --format=zip -o dist/debug_watermark-1.0.0.zip HEAD
   ```

## 예전 에셋 라이브러리에 넣은 값

godotengine.org/asset-library에 로그인한 뒤 Submit Asset에서 입력했습니다.

| 칸 | 넣은 값 |
| --- | --- |
| Asset Name | `Debug Watermark` |
| Description | 아래 "설명" |
| Category | `Tools` |
| License | `MIT` |
| Repository host | `GitHub` |
| Repository URL | `https://github.com/heekwankim0401-collab/godot-debug-watermark` |
| Issues URL | 비움. 사이트가 `.../godot-debug-watermark/issues`로 자동으로 채움 |
| Minimum Godot version | `4.2` |
| Asset Version | `1.0.0` |
| Download Commit | `432a7d86c10b739b526458889cd8347671c122c6` |
| Icon URL | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/icon.png` |
| Preview 1 (Image, 썸네일도 같은 주소) | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/thumbnail.png` |
| Preview 2 (Image, 썸네일도 같은 주소) | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/screenshot.png` |

- 아이콘은 256×256 PNG입니다. 규칙은 정사각형, 128×128 이상입니다.
- 비슷한 디버그 도구(Debug Menu, Monitor overlay, Debug Overlay)가 Tools 분류에 있어서
  Tools로 정했습니다.
- 사이트가 계산한 다운로드 주소는
  `https://github.com/heekwankim0401-collab/godot-debug-watermark/archive/432a7d86c10b739b526458889cd8347671c122c6.zip`
  입니다. 이 zip에 `addons/debug_watermark/`만 들어 있는 것을 확인했습니다.

## 새 에셋 스토어에 넣은 값

store.godotengine.org의 Upload Asset에서 시작합니다. Godot Account(sso.godotengine.org)
로그인이 필요합니다.

### 1단계: 퍼블리셔와 애셋 만들기

| 칸 | 넣은 값 |
| --- | --- |
| Publisher | 기존 퍼블리셔 `KHKHK`(URL 슬러그 `khkhk`) |
| Asset Name | `Debug Watermark` |
| Asset URL Slug | `debug-watermark` |
| Terms of Service 동의 | 체크(사용자 승인) |

퍼블리셔와 애셋의 URL 슬러그는 나중에 바꿀 수 없습니다. Continue를 누르면 초안(Draft)이
만들어지고, 아직 공개되지 않습니다.

### 2단계: Settings 탭

| 칸 | 넣은 값 |
| --- | --- |
| Asset Summary | `Show a DEBUG watermark in a corner of the game window in debug builds only.` |
| Detailed Description | 아래 "설명"(이 칸은 마크다운을 지원하지만 같은 글을 그대로 넣음) |
| Tags | `Debug`, `Overlay`, `HUD`, `Export`, `Testing` |
| Type | `Addon (tools, assets, etc...)` |
| License | `MIT` |
| Source Code URL | `https://github.com/heekwankim0401-collab/godot-debug-watermark` |
| Documentation URL | `https://github.com/heekwankim0401-collab/godot-debug-watermark#readme` |
| This asset uses AI generated assets and/or code | 체크 |
| AI Usage Explanation | 아래 "AI 사용 공개" |

### 3단계: Media 탭

| 칸 | 올린 파일 |
| --- | --- |
| Store Thumbnail | `media/thumbnail.png`(1280×720) |
| Featured Image | 비움(썸네일이 대신 쓰임) |
| Media | `media/store_screenshot_default.png`, `media/store_screenshot_dialog.png`(둘 다 1280×720) |

Media의 두 장은 테스트 프로젝트를 Godot 4.7.2에서 `--resolution 1280x720`으로 실행해 찍은
실제 화면입니다. 하나는 기본 화면이고, 하나는 창 안에 뜬 대화상자 위에 워터마크가 그려진
화면입니다. `media/screenshot.png`(1152×648)는 스토어의 최소 크기보다 작아서 스토어에는
쓰지 않았습니다.

### 4단계: Versions 탭

| 칸 | 넣은 값 |
| --- | --- |
| Version Name | `1.0.0` |
| Version Changelog | `First release.` |
| Stable | 체크 |
| Minimum Required Godot Version | `Godot 4.2` |
| Maximum Compatible Godot Version | `None` |
| Additional Information | 비움 |
| File | `dist/debug_watermark-1.0.0.zip`(6.62KB) |

Submit Version을 누르면 버전이 올라가고 "Pending Approval"로 표시됩니다.

### 5단계: Overview 탭

공개 조건 다섯 가지(썸네일, 요약, 설명, 태그 1개 이상, 라이선스)가 모두 체크된 것을 확인한
뒤 **Publish (submit for review)**를 눌렀습니다. 상태가 "Pending"으로 바뀌었고, 팀원이 검토한
뒤에 공개됩니다.

### 스토어에서 알게 된 규칙과 주의점

- 썸네일과 Media 이미지는 16:9여야 하고, 1280×720 이상, 600KB 이하입니다. 권장 형식은
  1920×1080 .webp입니다.
- AI Usage Explanation은 256자까지만 들어갑니다. 넘으면 저장할 때 "Field cannot be longer
  than 256 characters." 오류가 나고, 그때 입력한 태그가 사라집니다.
- 태그 입력칸에서 Enter를 누르면 태그가 추가되지 않고 Settings 양식 전체가 저장될 때가
  있습니다. 저장이 한 번 실패한 뒤에는 추천 태그 목록도 뜨지 않았습니다. 이때는 페이지를
  새로 열고, 태그를 입력한 뒤 아래에 뜨는 추천 태그를 클릭해서 넣습니다.
- 태그 규칙: 애셋 이름을 태그로 쓰면 안 되고, 이미 있는 태그의 단수형·복수형을 따로
  넣지 않습니다.
- 스토어 가이드라인은 zip에서 `.gitignore`, `.gitattributes` 같은 불필요한 파일을 빼고,
  스크립트 경고를 없애라고 권합니다. 이 애드온의 zip과 스크립트는 두 가지 모두 지킵니다.

## 설명 (영어, 두 곳 공통)

예전 라이브러리 양식은 마크다운을 지원하지 않으므로 그대로 붙여 넣었습니다.

```text
Debug Watermark shows a small "DEBUG" label in a corner of the game window when the game runs from a debug build, so you can tell debug builds from release builds at a glance, for example in screenshots, videos or bug reports from testers. Release exports show nothing.

Enable the plugin and it adds a DebugWatermark autoload. The text (with {project_name}, {project_version} and {godot_version} placeholders), corner, margin, canvas layer, font size, color, opacity, outline and an optional fade-out time are project settings. You can also hide it when you run the game from the editor, so it only appears in exported debug builds. The watermark ignores the mouse, so clicks go through to your game, and by default it is drawn above other CanvasLayers and embedded dialogs.

This add-on implements godot-proposals#1073. It was tested in Godot 4.2.2, 4.6.3 and 4.7.2, including debug and release exports in 4.7.2. Documentation, known limitations and a Korean version are in the repository.
```

## AI 사용 공개 (영어, 스토어용)

스토어는 AI로 만든 부분과 AI를 쓴 방식을 밝히라고 요구합니다. 칸이 256자까지만 받으므로
줄인 문장(212자)을 넣었습니다.

```text
Made with an AI coding assistant (Claude by Anthropic): it wrote the plugin code, tests, docs and the scenes that rendered the icon and thumbnail. Tested in real Godot 4.2.2, 4.6.3 and 4.7.2 with automated tests.
```

## 새 버전을 낼 때

1. `addons/debug_watermark/plugin.cfg`의 `version`을 올립니다.
2. 커밋하고 GitHub에 푸시합니다.
3. 예전 라이브러리: 내 애셋의 Edit에서 Asset Version과 Download Commit을 새 값으로
   바꿉니다. 바뀐 내용은 Description에 적을 수 있습니다.
4. 새 스토어: 새 버전의 zip을 만든 뒤 Versions 탭의 "Upload A New Version"에서 버전 이름,
   변경 내용, 최소 Godot 버전, zip을 넣고 Submit Version을 누릅니다.
