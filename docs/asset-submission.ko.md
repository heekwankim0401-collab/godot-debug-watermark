# 에셋 등록 자료

Debug Watermark를 Godot 공식 애셋 배포처에 올릴 때 쓰는 값과 순서입니다.
두 곳 모두 이름과 설명을 영어로 쓰라고 정해 두었습니다. 그래서 양식에 넣을 값은
영어로, 설명은 한국어로 적었습니다.

## 어디에 올리나

| 배포처 | 주소 | 어느 에디터에서 보이나 | 올리는 방식 |
| --- | --- | --- | --- |
| 예전 에셋 라이브러리 | https://godotengine.org/asset-library | Godot 4.0~4.6 에디터의 AssetLib 탭 | GitHub 저장소의 커밋 해시를 적음 |
| 새 에셋 스토어(베타) | https://store.godotengine.org | Godot 4.7 이상 에디터의 Asset Store 탭 | zip 파일을 직접 올림 |

애드온은 Godot 4.2 이상을 지원합니다(4.2.2, 4.6.3, 4.7.2에서 테스트). 그래서 두 곳
모두에 올릴 수 있습니다. 예전 라이브러리에 4.2로 등록하면 4.3~4.6 에디터에서도
보입니다.

## 올리기 전에 할 일

1. 이 저장소의 최신 커밋을 GitHub에 푸시합니다. 아이콘과 미리보기 주소는 푸시한 뒤에야
   열립니다.
2. 푸시한 커밋의 전체 해시를 확인합니다. 예전 라이브러리의 Download Commit 칸에
   넣습니다.

   ```powershell
   git rev-parse HEAD
   ```

3. 스토어에 올릴 zip을 만듭니다. `.gitattributes` 설정 때문에 zip에는
   `addons/debug_watermark/`만 들어갑니다(테스트 러너는 빠짐). `dist` 폴더는 git에
   올리지 않으므로 먼저 만듭니다.

   ```powershell
   New-Item -ItemType Directory -Force dist
   ```

   ```powershell
   git archive --format=zip -o dist/debug_watermark-1.0.0.zip HEAD
   ```

## 예전 에셋 라이브러리 양식 값

godotengine.org/asset-library에 로그인한 뒤 Submit Assets에서 입력합니다.
제출하면 검토 대기열에 들어가고, 검토에 며칠 걸릴 수 있습니다.

| 칸 | 넣을 값 |
| --- | --- |
| Asset Name | `Debug Watermark` |
| Category | `Tools` |
| Godot version | `4.2` |
| Version | `1.0.0` |
| Repository host | `GitHub` |
| Repository URL | `https://github.com/heekwankim0401-collab/godot-debug-watermark` |
| Issues URL | `https://github.com/heekwankim0401-collab/godot-debug-watermark/issues` |
| Download Commit | 위 2번에서 확인한 전체 커밋 해시 |
| Icon URL | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/icon.png` |
| License | `MIT` |
| Description | 아래 "설명" |
| Preview 1 (Image) | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/thumbnail.png` |
| Preview 2 (Image) | `https://raw.githubusercontent.com/heekwankim0401-collab/godot-debug-watermark/main/media/screenshot.png` |

- 아이콘은 256×256 PNG입니다. 규칙은 정사각형, 128×128 이상입니다.
- 비슷한 디버그 도구(Debug Menu, Monitor overlay, Debug Overlay)가 Tools 분류에 있어서
  Tools로 정했습니다.

## 새 에셋 스토어 양식 값

store.godotengine.org의 Upload Asset에서 입력합니다. 업로드 양식은 로그인해야 볼 수
있어서, 아래 값은 Rename on Create 준비 때 스토어의 guidelines·help 페이지에서 확인한
항목을 기준으로 했습니다. 양식에 다른 칸이 있으면 비슷한 값을 씁니다.

| 칸 | 넣을 값 |
| --- | --- |
| Name | `Debug Watermark` |
| Summary(한 줄) | `Show a DEBUG watermark in a corner of the game window in debug builds only.` |
| Description | 아래 "설명" |
| Thumbnail(16:9) | `media/thumbnail.png`(1280×720) |
| Tags | `Debug`, `Overlay`, `HUD`, `Export`, `Testing` |
| License | `MIT` |
| Version | `1.0.0` |
| 최소 Godot 버전 | `4.2` |
| 파일 | `dist/debug_watermark-1.0.0.zip` |
| AI 사용 공개 | 아래 "AI 사용 공개"(스토어 규칙상 **필수**) |

태그 규칙: 애셋 이름을 태그로 쓰면 안 되고, 이미 있는 태그의 단수형·복수형을 따로
넣지 않습니다.

## 설명 (영어, 두 곳 공통)

양식이 마크다운을 지원하지 않으므로 그대로 붙여 넣습니다.

```text
Debug Watermark shows a small "DEBUG" label in a corner of the game window when the game runs from a debug build, so you can tell debug builds from release builds at a glance, for example in screenshots, videos or bug reports from testers. Release exports show nothing.

Enable the plugin and it adds a DebugWatermark autoload. The text (with {project_name}, {project_version} and {godot_version} placeholders), corner, margin, canvas layer, font size, color, opacity, outline and an optional fade-out time are project settings. You can also hide it when you run the game from the editor, so it only appears in exported debug builds. The watermark ignores the mouse, so clicks go through to your game, and by default it is drawn above other CanvasLayers and embedded dialogs.

This add-on implements godot-proposals#1073. It was tested in Godot 4.2.2, 4.6.3 and 4.7.2, including debug and release exports in 4.7.2. Documentation, known limitations and a Korean version are in the repository.
```

## AI 사용 공개 (영어, 스토어용)

스토어는 AI로 만든 부분과 AI를 쓴 방식을 밝히라고 요구합니다. 아래 문장을 그대로 쓰거나
고쳐서 씁니다.

```text
This add-on was made with the help of an AI coding assistant (Claude by Anthropic). The AI wrote the plugin code, the automated tests, the documentation, and the small Godot scenes that rendered the icon and the thumbnail. The thumbnail shows the real add-on at its default settings over a simple demo scene, rendered in Godot 4.7.2; the second preview is a screenshot of the test project. The behavior was tested in real Godot 4.2.2, 4.6.3 and 4.7.2 with the automated tests.
```

## 새 버전을 낼 때

1. `addons/debug_watermark/plugin.cfg`의 `version`을 올립니다.
2. 커밋하고 GitHub에 푸시합니다.
3. 예전 라이브러리: 내 애셋의 Edit에서 Version과 Download Commit을 새 값으로 바꿉니다.
   바뀐 내용은 Description에 적을 수 있습니다.
4. 새 스토어: 새 버전의 zip을 만들어 새 릴리스로 올리고 변경 내용을 적습니다.
