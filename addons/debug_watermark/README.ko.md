# Debug Watermark

디버그 빌드로 게임을 실행하면 게임 창 구석에 **DEBUG** 워터마크를 띄웁니다.
릴리스로 내보낸 게임에는 아무것도 나오지 않습니다. Godot 4.2 이상에서 씁니다.

1. 이 폴더를 `res://addons/debug_watermark/`에 둡니다(Godot 4.4 이상에서는 `.uid`
   파일도 함께 둡니다).
2. **프로젝트 > 프로젝트 설정 > 플러그인**에서 **Debug Watermark**를 켭니다.
   `DebugWatermark` 오토로드가 추가됩니다.
3. 문구, 구석 위치, 여백, 층, 색, 불투명도 등은 **프로젝트 설정 > Debug Watermark**에서
   바꿉니다.

워터마크는 마우스를 무시하므로 클릭은 그대로 게임으로 갑니다. 릴리스 빌드에서도
`DebugWatermark` 노드는 남아 있지만 아무것도 그리지 않습니다.

전체 설명, 알려진 한계, 테스트:
https://github.com/heekwankim0401-collab/godot-debug-watermark

MIT 라이선스(`LICENSE` 참고).
