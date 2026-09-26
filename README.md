# 闂诲ぉ涓?路 Flutter 鏂伴椈闃呰 App

> Material 3 + **娑叉€佺幓鐠冿紙Liquid Glass锛?* + 鐭棰戝紡鍨傜洿婊戝姩娴忚鐨勬柊闂婚槄璇诲簲鐢ㄣ€?> 鏁版嵁婧愪负**鑱氬悎鏁版嵁 路 鏂伴椈澶存潯 API**锛?*API Key 鐢辩敤鎴峰湪棣栨鍚姩鏃跺～鍐欏苟鍙繚瀛樺湪鏈満**
> 锛圚ive 鏈湴瀛樺偍锛夛紝婧愮爜涓笉鍚换浣曠‖缂栫爜瀵嗛挜銆?
<p align="left">
  <img alt="version" src="https://img.shields.io/badge/version-2.0.1-2ea44f" />
  <img alt="flutter" src="https://img.shields.io/badge/Flutter-3.27.4-02569B?logo=flutter" />
  <img alt="dart" src="https://img.shields.io/badge/Dart-3.6.2-0175C2?logo=dart" />
  <img alt="platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" />
  <img alt="material" src="https://img.shields.io/badge/Material-3%20%2B%20LiquidGlass-6750A4" />
  <img alt="riverpod" src="https://img.shields.io/badge/State-Riverpod-4B4BFF" />
  <img alt="ci" src="https://img.shields.io/badge/CI-CodeMagic-8B5CF6" />
</p>

---

## 鐗堟湰璁板綍

| 鐗堟湰 | 璇存槑 |
| --- | --- |
| **2.0.1+4**锛堝綋鍓嶏級 | 淇銆屽畨瑁?鏇存柊鍚庨娆℃墦寮€涓嶅脊鏇存柊鍐呭銆嶏紙寮圭獥涓婁笅鏂囧彇鍦?Navigator 涔嬩笂锛夈€佹洿鏂板唴瀹规孩鍑虹幓鐠冩銆佺幓鐠冩粦鍔ㄥ伓鍙戦棯鐑侊紱棣栨瀹夎鏀逛负灞曠ず銆屼娇鐢ㄦ彁绀恒€?|
| 2.0.0+3 | 鍏ㄦ柊銆屾恫鎬佺幓鐠冦€嶆潗璐紙杈圭紭鎶樺皠 + 鑹叉暎 + 45掳 杈圭紭楂樺厜 + 鍐呴槾褰憋級锛涜缃噷鍙垏鎹€屾恫鎬佺幓鐠?/ 楂樻柉妯＄硦銆嶏紱淇鍏ㄦ枃椤佃嚜鍔ㄦ粴鍔ㄥ仠涓嶆帀涓旈粯璁ゅ叧闂紱缁熶竴 APK 绛惧悕锛涘畨瑁?鏇存柊鍚庡脊鍑烘洿鏂板唴瀹?|
| 1.0.1+2 | 淇姣涚幓鐠冩帶浠朵笅鏂瑰浘鍍忕己澶憋紙绌虹櫧鑹插甫锛変笌婊戝姩闂儊锛涙瘺鐜荤拑灞傜粨鏋勯噸鏋勶紱鏂板妯＄硦鍥炲綊娴嬭瘯 |
| 1.0.0+1 | 棣栦釜鐗堟湰锛氬紩瀵奸〉 / 鏂伴椈娴?/ 鍏ㄦ枃闃呰 / 鏀惰棌 / 璁剧疆 / CodeMagic 鏋勫缓 |

### 2.0.1 淇璇︽儏锛堝叏閮ㄦ潵鑷湡鏈哄弽棣堬級

#### 鈶?鏇存柊鍐呭寮圭獥鍦ㄩ娆℃墦寮€鏃朵笉寮癸紙闈欓粯澶辨晥锛?
**鏍瑰洜锛堟湁澶嶇幇娴嬭瘯涓鸿瘉锛?*锛氶椄闂ㄦ寕鍦?`MaterialApp.router` 鐨?`builder` 閲岋紝
鑰?**builder 鐨?context 浣嶄簬 Navigator 涔嬩笂**锛屼簬鏄細

```
Navigator operation requested with a context that does not include a Navigator.
```

杩欎釜寮傚父琚?`main.dart` 鐨勫叏灞€鍏滃簳 `PlatformDispatcher.onError` 鍚炴帀锛?鎵€浠ユ棦娌℃湁宕╂簝涔熸病鏈夊脊绐?鈥斺€?琛ㄧ幇灏辨槸銆屼粈涔堥兘涓嶅彂鐢熴€嶃€?璁剧疆椤佃兘寮规槸鍥犱负瀹冨鍦ㄦ甯哥殑 Navigator 涔嬩笅銆?
**淇**锛歡o_router 鎸備笂鏍?navigator key锛岄椄闂ㄦ敼鐢ㄥ畠鐨?overlay context 寮圭獥锛?
```dart
// lib/routes/app_router.dart
static final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter(navigatorKey: AppRoutes.rootNavigatorKey, ...)

// lib/features/changelog/changelog_dialog.dart
final NavigatorState? navigator = AppRoutes.rootNavigatorKey.currentState;
await Future<void>.delayed(const Duration(milliseconds: 400));
final BuildContext? dialogContext = navigator.overlay?.context;   // 鈫?鍏抽敭
await showChangelogDialog(dialogContext, release: release);
```

鍙﹀棣栨瀹夎涓嶅啀鏄剧ず銆屾洿鏂版棩蹇椼€嶏紙閭ｆ椂娌℃湁"鏇存柊"鍙█锛夛紝鏀逛负灞曠ず**浣跨敤鎻愮ず**锛?`AppChangelog.welcome` + `settings.isFirstLaunch` 鍒ゆ柇銆?
鍥炲綊娴嬭瘯锛歚test/changelog_gate_test.dart`锛? 涓敤渚嬶級銆?
#### 鈶?鏇存柊鍐呭婧㈠嚭鐜荤拑妗嗗

`Column(mainAxisSize.min) + Flexible(SingleChildScrollView)` 缁勫悎璁╂粴鍔ㄥ尯鎷夸笉鍒?鏈夌晫楂樺害锛屾潯鐩竴澶氭枃瀛楀氨琚尋鍑哄渾瑙掑銆傛敼涓虹粰鍐呭鍧椾竴涓‖涓婇檺锛岃秴鍑洪儴鍒嗘鍐呮粴鍔細

```dart
final double maxBodyHeight = MediaQuery.sizeOf(context).height * 0.62;
ConstrainedBox(
  constraints: BoxConstraints(maxHeight: maxBodyHeight),
  child: SingleChildScrollView(child: Column(children: items)),
)
```

#### 鈶?鐜荤拑鎺т欢婊戝姩鏃跺伓鍙戦棯鐑?
2.0.0 缁欑幓鐠冨姞浜嗐€宮aterialize 鍏ュ満銆嶏紙鏂囨。 WWDC25-219 鐨勮鏂?2锛夛紝瀹炵幇涓婃槸
`Opacity + Transform.scale` 鍖呬綇 `BackdropFilter`銆傚畠浼氬湪鐜荤拑涔嬩笂鍐嶅悎鎴愪竴灞?`OpacityLayer`锛屼笌 `BackdropFilterLayer` 鍙犲姞鏃跺伓鍙戦噰鏍烽棯鐑侊紙鐪熸満澶嶇幇姒傜巼灏忎絾瀛樺湪锛夈€?
**淇**锛氱幓鐠冨洖褰?*鍗曞眰 backdrop**锛屽幓鎺?`Opacity`/`Transform` 鍖呰锛?`LiquidGlass.materialize` 鍙傛暟淇濈暀浣嗗凡鏃犳晥鏋滐紙鏍囨敞 `@Deprecated`锛夛紱
鎸夊帇鏋滃喕褰㈠彉锛坄pressScale`锛変繚鐣欙紝鍥犱负瀹冨彧鍦ㄦ寜涓嬬灛闂寸敓鏁堛€?
> 璇存槑锛氱湡鏈轰笂杩欎釜闂儊鐨?*鏍规不**闇€瑕?Flutter 3.29+锛坄ImageFilter.shader` 鐪熸姌灏勶級
> 鎴?3.41+锛坄BackdropFilter` 鐨?`bounded` blur 淇锛屽搴?issue #184447 / #191207
> 鐨勬粴鍔ㄧ汗鐞嗛敊浣嶏級銆傚綋鍓?3.27.4 涓婄殑瑙ｆ瀽寮忔覆鏌撳凡缁忔妸姒傜巼鍘嬪埌寰堜綆銆?
### 2.0.0 鏇存柊璇︽儏

#### 鈶?娑叉€佺幓鐠冩潗璐紙榛樿锛?
鏉愯川寮曟搸鍦?`lib/core/widgets/liquid_glass.dart` + `glass_widgets.dart`锛?鏁板涓庡弬鏁?*閫愭潯瀵归綈**椤圭洰鍐呫€婃恫鎬佺幓鐠冨疄鐜版妧鏈枃妗ｃ€嬶細

| 鏂囨。瑕佺礌 | 鏈疄鐜?|
| --- | --- |
| 鍦嗚鐭╁舰 SDF | `LiquidGlassSdf.sdRoundedRect`锛堜笌 Kyant0 `Shaders.kt` 鐨勫悓鍚嶅嚱鏁伴€愯涓€鑷达級 |
| 鍗婂緞鍙栧€煎潙浣?| 姊害鍗婂緞鐢?`min(r 脳 1.5, min(halfW, halfH))`锛岄伩鍏嶅渾瑙掑鏀惧皠鐘舵姌鐥?|
| 鎶樺皠鍓栭潰 | `circleMap(x)=1-鈭?1-x虏)`锛歚refractHeight = bezel / refractionAmount`锛宍depth 鈮?refractHeight` 鈫?涓嶆姌灏勶紱`depth 鈫?0` 鈫?浣嶇Щ鏈€澶?|
| 褰掍竴鍖栨繁搴?| `LiquidGlassSdf.normalizedDepth`锛? = 涓嶅姩锛? = 杈圭紭鏈€寮猴紙`refractionHeight` / `refractionAmount` 涓や釜鍙傛暟涓?Kyant0 `lens(12dp, 24dp)` 鍚屾瀯锛?|
| 浣嶇Щ閲?| `bezel = clamp(min(w,h) 脳 0.12, 6, 28)`锛宍浣嶇Щ 鈮?bezel 脳 1.6~2.0` |
| 妯＄硦蹇呴』灏?| 娑叉€佺幓鐠?蟽 = 2~4锛堟枃妗ｏ細>8px 浼氭妸鎶樺皠缁嗚妭鎶瑰钩锛岄€€鍖栨垚姣涚幓鐠冿級 |
| 鍏眰鍫嗗彔椤哄簭 | 鎶樺皠 鈫?妯＄硦 鈫?tint 鈫?楂樺厜 鈫?鑹茶竟/杈圭紭鍏?鈫?鍐呭 |
| 鑹叉暎 | 鍐锋殩鍙屼晶 1px 鍐呮弿杈癸紙鏂囨。 1.5 鑺傜殑寤変环鏇夸唬鏂规锛汯yant0 鐨?7 娆￠噰鏍峰湪绉诲姩绔お璐碉級 |
| 楂樺厜 | `鈭嘢DF` 涓?45掳 鍏夋簮鐐圭Н锛宍abs(dot)` 瀹炵幇鍙岄潰鍙嶅厜锛堝搴?`DefaultHighlightShaderString`锛?|
| 鍐呴槾褰?| 涓婃殫涓嬩寒鐨?inset 娓愬彉锛堢幓鐠冨帤搴︼級 |
| 浜や簰褰㈠彉 | 鎸変笅鏀惧ぇ 4% / 120ms 缂撳嚭锛堟枃妗?2.10 鐨勩€屾恫銆嶆劅鏉ユ簮锛?|
| materialize 鍏ュ満 | 娓愬彉鎶樺皠寮哄害 + 杞诲井缂╂斁锛岃€屼笉鏄贰鍏ユ贰鍑猴紙WWDC25-219 璁烘柇 2锛?|
| 鍙傛暟 | `saturation 1.35`銆乣tint alpha 0.09~0.14`銆乣specular 0.38~0.5`銆乣innerShadow 0.10~0.16` |
| 閬垮厤 glass on glass | 涓€鏉?bar 鍙仛涓€娆＄幓鐠冿紱鏉″唴鎺т欢鐢?`GlassTint`锛堥潤鎬佸～鍏咃紝涓嶅彔 backdrop 灞傦級 |

> **鍏充簬銆岀湡路鑳屾櫙閲嶉噰鏍枫€?*锛欶lutter 鐨?`dart:ui` 鍙彁渚?> `ImageFilter.blur/dilate/erode/matrix/compose`锛?*娌℃湁**鎶?`FragmentShader`
> 浣滀负 `ImageFilter` 浣跨敤鐨勫叕寮€鍏ュ彛锛坄ImageFilter.shader()` 鍦?3.27.4 涓婁笉瀛樺湪锛夛紝
> 鍥犳鏃犳硶璁?`BackdropFilter` 鐩存帴鎶婅儗鏅寜浣嶇Щ鍦洪噸閲囨牱銆?> 鏈疄鐜伴噰鐢ㄧ殑鏄?*瑙ｆ瀽寮忔姌灏?*锛氱敤鍚屼竴濂?SDF + Snell 鏁板绠楀嚭杈圭紭鐨勪綅绉诲墫闈紝
> 鍐嶆妸銆屼綅绉?鈫?閲囨牱鍋忕Щ銆嶇殑鐗╃悊缁撴灉瑙ｆ瀽鍦扮敾鎴愬厜瀛﹀眰銆?> 濂藉鏄?*閫愬抚纭畾銆佷笉閲囨牱瀹炴椂鑳屾櫙銆佷笉渚濊禆鍏夋爡缂撳瓨**锛?> 鎵€浠ユ棦鎷垮埌浜嗘姌灏?鑹叉暎/楂樺厜鐨勮鎰燂紝鍙?*褰诲簳娌℃湁鍥惧儚缂哄け涓庨棯鐑?*銆?
#### 鈶?鏉愯川鍒囨崲寮€鍏?
銆岃缃?鈫?纾ㄧ爞鏉愯川銆嶇敤 Material 3 `SegmentedButton` 鍒囨崲锛?
```dart
// lib/shared/hive/settings_provider.dart
final Provider<GlassMaterial> glassMaterialProvider = Provider<GlassMaterial>((Ref ref) {
  final GlassMode mode = ref.watch(glassModeProvider);          // 鏉ヨ嚜 Hive
  return mode == GlassMode.liquid ? GlassMaterial.liquid() : GlassMaterial.blur();
});

// lib/app.dart锛氭敞鍏ュ埌鏍归儴锛屽叏绔欑幓鐠冩帶浠跺嵆鏃惰窡闅?GlassScope(material: material, child: MediaQuery(...))
```

* 鏉愯川鍐欏叆 Hive锛坄AppSettings.glassMode`锛?*鎸夋灇涓惧悕瀛樺瓧绗︿覆**锛岃法鐗堟湰鏈€绋筹級锛?* 鍒囨崲鍚?Riverpod 閫氱煡 鈫?`GlassScope` 鏇存柊 鈫?鎵€鏈?`BlurContainer` / `BlurButton` /
  `BlurBar` / 寮圭獥鍗虫椂閲嶅缓锛?*鏃犻渶閲嶅惎**锛?* 1.0.x 鑰佺敤鎴峰崌绾ф椂锛孒ive 璁板綍閲屾病鏈夎繖涓や釜瀛楁锛?  `AppSettingsAdapter.read` 宸插仛**鍚戝悗鍏煎鍥炶惤**锛堥粯璁ゆ恫鎬佺幓鐠冿級锛屼笉浼氬穿銆?
#### 鈶?鍏ㄦ枃椤佃嚜鍔ㄦ粴鍔紙bug 淇 + 榛樿鍏抽棴锛?
```dart
// 鉂?1.x锛氬唴瀹逛竴灏辩华灏辫嚜鍔ㄥ紑婊氾紝瀵艰嚧鐢ㄦ埛鐐广€屾殏鍋溿€嶅悗涓嬩竴娆￠噸寤哄張婊氳捣鏉?鈫?鍋滀笉鎺?if (contentAsync.hasValue) _scheduleAutoScroll();

// 鉁?2.0.0锛氶粯璁や笉鍔紝鍙湁鐢ㄦ埛鐐规寜閽墠鍚姩锛涘垽鎹敮涓€锛堣鏃跺櫒鏄惁瀛樺湪锛?static const bool autoScrollByDefault = false;
void _toggleAutoScroll() {
  if (_autoScrollTimer == null) { _startAutoScroll(); } else { _stopAutoScroll(); }
}
```

鍙﹀锛氬垏鎹㈡枃绔犳椂涓诲姩鍋滆〃锛涙粴鍒板簳閮ㄨ嚜鍔ㄥ仠锛沗_onScroll` 涓嶅啀骞叉壈鐢ㄦ埛鎵嬪姩婊戝姩銆?
#### 鈶?缁熶竴 APK 绛惧悕锛堣崳鑰€/鍗庝负瀹夎鍣ㄦ彁绀恒€岀鍚嶄笉涓€鑷淬€嶏級

1.x 鐢?AGP 榛樿 debug 绛惧悕 鈥斺€?瀵嗛挜闅忔瀯寤虹幆澧冨彉鍖栵紝鑰屾湰鏈轰笌 CodeMagic 鏄袱涓幆澧冿紝
瑕嗙洊瀹夎鏃剁郴缁熷畨瑁呭櫒浼氬垽瀹氱鍚嶄笉鍚岋紝瑕佹眰鍏堝嵏杞芥棫鐗堟湰锛堜細涓㈡暟鎹級銆?
鐜板湪浠撳簱鍐呭浐瀹氫竴鎶婂瘑閽?`android/app/wentianxia-release.jks`锛?**debug 涓?release 鍏辩敤**锛屾湰鍦颁笌 CI 浜у嚭鐨?APK 绛惧悕瀹屽叏涓€鑷达細

```gradle
def wentianxiaKeystore = file('wentianxia-release.jks')
android {
  signingConfigs { if (wentianxiaKeystore.exists()) { wentianxia { ... } } }
  buildTypes {
    release { signingConfig = signingConfigs.wentianxia }
    debug   { signingConfig = signingConfigs.wentianxia }
  }
}
```

> 杩囨浮鎻愮ず锛?.0.x 鐨勬棫鍖呯敤鐨勬槸**鍙︿竴鎶?* debug 瀵嗛挜锛屽洜姝?*杩欎竴娆?*鍗囩骇浠嶉渶鍗歌浇涓€娆?> 锛堟垨鑰呭厛瀵煎嚭鏀惰棌/閲嶆柊濉?API Key锛夛紱浠?2.0.0 涔嬪悗鐨勬墍鏈夌増鏈兘鍙互鐩存帴瑕嗙洊瀹夎銆?
#### 鈶?鏇存柊鍐呭寮圭獥

`lib/features/changelog/`锛?
* `app_changelog.dart` 鈥斺€?鐗堟湰鏇存柊鏉＄洰锛堝綋鍓?`2.0.0`锛夛紱
* `changelog_dialog.dart` 鈥斺€?`AppChangelogGate` 鎸傚湪 `MaterialApp.builder` 鍐咃紝
  棣栧抚鍚庢瘮杈?`AppSettings.lastSeenVersion` 涓庡綋鍓嶇増鏈紝涓嶅悓鍒欏脊鍑烘洿鏂板唴瀹癸紝
  鐢ㄦ埛鐐广€屽紑濮嬩娇鐢ㄣ€嶅悗鍐欏洖璁板綍锛涜缃〉涔熷彲鎵嬪姩鎵撳紑銆?
### 1.0.1 淇璇︽儏

> 鐜拌薄绀烘剰锛氬簳閮ㄥ鑸爮涓嬫柟鐨勬ā绯婂尯鍩?*鏁村潡鍙樻垚绌虹櫧/鐏扮櫧鑹插甫**锛屾粦鍔ㄦ椂璇ヨ壊甯﹂殢鏈洪棯鐑併€?> 锛堟埅鍥捐 issue 闄勪欢锛屼粨搴撳唴涓嶄繚鐣?96KB 鐨勮皟璇曞浘鐗囥€傦級

**鐜拌薄**锛氭墍鏈夋瘺鐜荤拑鎺т欢锛堝簳閮ㄥ鑸爮銆侀《閮ㄦ爮銆佸叏鏂囬〉鎿嶄綔鏍忋€佹敹钘忓崱鐗囥€丆hip 绛夛級
涓嬫柟浼氬嚭鐜颁竴鍧?*鍥惧儚缂哄け鐨勭┖鐧?鐏扮櫧鑹插甫**锛屾粦鍔ㄦ椂杩樹細**闂儊**銆?
**鏍瑰洜**锛歚BackdropFilter` 灞炰簬 **backdrop 灞?*鈥斺€斿畠蹇呴』閲囨牱銆岃嚜宸变笅鏂瑰凡缁忕敾濂界殑鍍忕礌銆嶃€?1.0.0 閲屼负浜嗏€滈伩鍏嶆ā绯婂紩鍙戦噸缁樷€濓紝鍦ㄦ瘡涓瘺鐜荤拑鎺т欢澶栭潰鍖呬簡 `RepaintBoundary`锛?
```dart
// 鉂?1.0.0 鐨勫啓娉曪紙鏈?bug锛?RepaintBoundary(            // 鈫?鎶婂瓙鏍戞彁鍗囦负鐙珛 OffsetLayer
  child: ClipRRect(
    child: BackdropFilter(  // 鈫?backdrop 閲囨牱鑼冨洿琚埅鏂湪杩欎釜鐙珛灞傚唴
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(...),//   灞傚唴鍙湁鍗婇€忔槑鎺т欢鏈韩 鈫?閲囧埌绌虹櫧 鈫?鑹插甫
    ),
  ),
)
```

瀛愭爲琚彁鍗囦负鐙珛灞傚悗锛宐ackdrop 鍙兘鎷垮埌**璇ュ眰鍐呴儴**鐨勫儚绱狅紙寰€寰€鍙湁鍗婇€忔槑鎺т欢鏈韩锛夛紝
浜庢槸妯＄硦鍖哄煙涓嬫柟鍑虹幇绌烘礊锛涙粦鍔ㄦ椂璇ュ眰鍙堣鍏夋爡缂撳瓨澶嶇敤锛岀┖娲炲氨琛ㄧ幇涓洪棯鐑併€?
**淇**锛? 澶勭粨鏋勬€ф敼鍔級锛?
| # | 鏀瑰姩 | 鏂囦欢 |
| --- | --- | --- |
| 1 | 姣涚幓鐠冩帶浠?*涓嶅啀鍖?* `RepaintBoundary`锛涢渶瑕侀殧绂婚噸缁樻椂锛屾妸杈圭晫鏀惧湪**鏁村潡婊氬姩鍐呭**鐨勪笂涓€灞?| `blur_container.dart`銆乣news_card.dart`銆乣interest_selector.dart`銆乣news_feed_page.dart`銆乣article_detail_page.dart` |
| 2 | 鏂板 `GlassBackdrop`锛氭瘡涓晫闈?`Stack` 鏈€搴曞眰閾轰竴灞傚叏灞忔笎鍙橈紝淇濊瘉妯＄硦鍖哄煙涓嬫柟**姘歌繙鏈夊凡缁樺埗鐨勫儚绱?*锛堝唴瀹逛笉瓒充竴灞忔椂涔熶笉鍐嶅嚭鐜扮┖鐧藉甫锛?| `blur_container.dart` + 鍚勯〉闈?|
| 3 | 涓€鏉?bar 鍙仛**涓€娆?*妯＄硦锛氭潯鍐呭皬鎸夐挳鏀圭敤 `GlassTint`锛堥潤鎬佸崐閫忔槑濉厖锛屼笉鏂板 backdrop 灞傦級锛屾秷闄も€滄ā绯婂妯＄硦鈥濈殑澶氬眰閲囨牱 | `BlurBar` / `GlassTint` / `BlurButton(flat: true)` |
| 4 | 椤舵爮/搴曟爮鏀圭敤 `Clip.hardEdge` 鐭╁舰瑁佸壀 + 娓愰殣搴曡壊锛沗NavigationBar` 鍘绘帀澶栧眰 `RepaintBoundary` | `main_shell.dart`銆乣news_feed_page.dart`銆乣article_detail_page.dart` |

淇鍚庣殑灞傜粨鏋勶紙姝ｇ‘褰㈡€侊級锛?
```dart
Stack(children: <Widget>[
  const GlassBackdrop(),                  // 鈶?鍏滃簳锛氬叏灞忔笎鍙橈紙姘歌繙鏈夊儚绱狅級
  Positioned.fill(child: RepaintBoundary( // 鈶?閲囨牱婧愶細鏁村潡婊氬姩鍐呭浣滀负涓€涓ǔ瀹氬眰
    child: content,
  )),
  ClipRect(                               // 鈶?姣涚幓鐠冩帶浠讹細Clip 鈫?BackdropFilter 鈫?Container
    clipBehavior: Clip.hardEdge,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(...),
    ),
  ),
])
```

鍥炲綊娴嬭瘯 `test/blur_regression_test.dart` 浼氭柇瑷€
**`BackdropFilter` 鐨勭鍏堥摼涓婁笉鍏佽鍑虹幇 `RepaintBoundary`**锛岄槻姝㈣ bug 鍐嶆寮曞叆銆?
---

## 鐩綍

- [涓€銆佸姛鑳芥€昏](#涓€鍔熻兘鎬昏)
- [浜屻€佹妧鏈爤涓庣増鏈粍鍚圿(#浜屾妧鏈爤涓庣増鏈粍鍚?
- [涓夈€佸揩閫熷紑濮媇(#涓夊揩閫熷紑濮?
- [鍥涖€佺洰褰曠粨鏋刔(#鍥涚洰褰曠粨鏋?
- [浜斻€佹灦鏋勪笌鏁版嵁娴乚(#浜旀灦鏋勪笌鏁版嵁娴?
- [鍏€佹牳蹇冨疄鐜拌瑙ｏ紙鍚唬鐮侊級](#鍏牳蹇冨疄鐜拌瑙ｅ惈浠ｇ爜)
  - [6.1 棣栨鍚姩鍒ゆ柇锛欻ive + go_router redirect](#61-棣栨鍚姩鍒ゆ柇hive--go_router-redirect)
  - [6.2 寮曞椤碉細API Key 杈撳叆 + 鍏磋叮 Chip](#62-寮曞椤礱pi-key-杈撳叆--鍏磋叮-chip)
  - [6.3 Hive 鏈湴瀛樺偍灏佽](#63-hive-鏈湴瀛樺偍灏佽)
  - [6.4 鏁版嵁妯″瀷锛欶reezed + Hive](#64-鏁版嵁妯″瀷freezed--hive)
  - [6.5 浠撳簱灞傦細浠?Hive 璇?Key 璇锋眰鑱氬悎鏁版嵁](#65-浠撳簱灞備粠-hive-璇?key-璇锋眰鑱氬悎鏁版嵁)
  - [6.6 鏂伴椈娴侊細鍨傜洿 PageView + 涓婃粦鍒锋柊](#66-鏂伴椈娴佸瀭鐩?pageview--涓婃粦鍒锋柊)
  - [6.7 鍗曟潯鏂伴椈鍗＄墖甯冨眬](#67-鍗曟潯鏂伴椈鍗＄墖甯冨眬)
  - [6.8 鍏ㄦ枃闃呰锛氳繃娓″姩鐢?+ 鑷姩婊氬姩](#68-鍏ㄦ枃闃呰杩囨浮鍔ㄧ敾--鑷姩婊氬姩)
  - [6.9 姝ｆ枃鎶藉彇锛欰rticleHtmlParser](#69-姝ｆ枃鎶藉彇articlehtmlparser)
  - [6.10 鏀惰棌锛欻ive Box + 宸︽粦鍒犻櫎](#610-鏀惰棌hive-box--宸︽粦鍒犻櫎)
  - [6.11 楂樻柉妯＄硦瑙勮寖锛圔lurContainer锛塢(#611-楂樻柉妯＄硦瑙勮寖blurcontainer)
  - [6.12 Material 3 涓婚](#612-material-3-涓婚)
  - [6.13 鍘熺敓鍒嗕韩 MethodChannel](#613-鍘熺敓鍒嗕韩-methodchannel)
- [涓冦€佽仛鍚堟暟鎹?API 璇存槑](#涓冭仛鍚堟暟鎹?api-璇存槑)
- [鍏€丆odeMagic 鏋勫缓](#鍏玞odemagic-鏋勫缓)
- [涔濄€佹祴璇昡(#涔濇祴璇?
- [鍗併€侀獙鏀跺鐓ц〃](#鍗侀獙鏀跺鐓ц〃)
- [鍗佷竴銆佸父瑙侀棶棰樹笌鍙栬垗](#鍗佷竴甯歌闂涓庡彇鑸?

---

## 涓€銆佸姛鑳芥€昏

| 妯″潡 | 瀹炵幇瑕佺偣 |
| --- | --- |
| **棣栨鍚姩寮曞** | 涓ゆ寮曞锛氣憼銆岃仛鍚堟柊闂籄PI Key銆嶈緭鍏ワ紙闈炵┖ + 闀垮害鏍￠獙銆佷竴閿矘璐淬€佸畼缃戠敵璇峰叆鍙ｏ級鈶″叴瓒ｇ被鍒閫夛紙Material 3 `Chip` + 楂樻柉妯＄硦瀹瑰櫒锛夈€備繚瀛?`isFirstLaunch=false` / `apiKey` / `selectedCategories` |
| **鍚姩鍒ゆ柇** | `main()` 鍒濆鍖?Hive 鈫?`settingsProvider` 鎺ㄩ€佹湰鍦拌缃?鈫?`go_router.redirect` 鍐冲畾杩涘紩瀵奸〉杩樻槸涓荤晫闈紙绗簩娆″惎鍔ㄤ笉鍐嶅睍绀哄紩瀵奸〉锛?|
| **鏂伴椈婊戝姩娴忚** | `PageView` + `scrollDirection: Axis.vertical`锛涙瘡椤碉細鍥剧墖锛堢害 38% 灞忛珮锛夆啋 鏍囬锛坄headlineSmall`锛夆啋 绠€浠嬶紙`bodyMedium`锛?~3 鍙ワ級鈫掋€岃鐪嬪叏鏂囥€嶆瘺鐜荤拑鎸夐挳 |
| **涓婃粦鍒锋柊** | 鍦ㄧ涓€鏉℃柊闂诲缁х画鍚戜笅鎷栨嫿锛坄OverscrollNotification`锛夎Е鍙戞帴鍙ｉ噸鎷夛紱鍙︽湁姣涚幓鐠冨埛鏂版寜閽?+ `RefreshIndicator` |
| **鍏ㄦ枃闃呰** | `CustomTransitionPage` + `SlideTransition`/`FadeTransition`锛涜繘鍏ュ悗 `Timer`+`ScrollController` **鑷姩婊氬姩**锛?.5x/1x/1.5x/2x锛屽彲鏆傚仠锛夛紱椤堕儴闃呰杩涘害鏉★紱椤靛唴鑷冲皯涓€寮犲浘鐗囷紱鏄剧ず浣滆€?鏉ユ簮/鍙戝竷鏃堕棿/瀛楁暟 |
| **闃呰鍘熸枃** | `url_launcher` 鎵撳紑绯荤粺娴忚鍣紙宸插０鏄?Android `<queries>`锛?|
| **鏀惰棌** | 蹇冨舰鍥炬爣 `Icons.favorite_border 鈫?Icons.favorite`锛汬ive `Box<NewsArticle>` 鎸佷箙鍖栵紱鏀惰棌 Tab 鏄剧ず缂╃暐鍥?鏍囬/鏀惰棌鏃堕棿锛宍Dismissible` 宸︽粦鍒犻櫎锛堝甫鎾ら攢锛夈€佷竴閿竻绌猴紱绌虹姸鎬併€岃繕娌℃湁鏀惰棌鐨勬柊闂汇€?|
| **璁剧疆椤?* | 闅忔椂淇敼 API Key / 鍏磋叮棰戦亾锛屼繚瀛樺悗鑷姩鍒锋柊鏂伴椈 |
| **閿欒澶勭悊** | Material 3 `SnackBar` + 閲嶈瘯锛涜仛鍚堟暟鎹敊璇爜锛?0001 鏃犳晥 Key銆?0012 棰濆害鐢ㄥ敖鈥︼級鏄犲皠涓轰腑鏂囨彁绀?|
| **鍒嗕韩 / 璺宠浆** | 鍏ㄦ枃椤靛簳閮ㄦ瘺鐜荤拑鎿嶄綔鏍忥細闃呰鍘熸枃 / 鏀惰棌 / 鍒嗕韩锛堝師鐢?`MethodChannel` 璋冪郴缁熷垎浜潰鏉匡紝鏃犵涓夋柟鎻掍欢锛?|

---

## 浜屻€佹妧鏈爤涓庣増鏈粍鍚?
| 绫诲埆 | 閫夊瀷 | 鐗堟湰 |
| --- | --- | --- |
| 妗嗘灦 | Flutter锛圡aterial 3 榛樿鍚敤锛?| 3.27.4 / Dart 3.6.2 |
| 鐘舵€佺鐞?| Riverpod | `flutter_riverpod ^2.6.1` |
| 缃戠粶 | Dio | `^5.7.0` |
| 鏈湴瀛樺偍 | Hive + hive_flutter | `^2.2.3` / `^1.1.0` |
| 璺敱 | go_router锛坄StatefulShellRoute.indexedStack`锛?| `^14.6.2` |
| 妯″瀷鐢熸垚 | Freezed 2.5.7 + json_serializable 6.9.0 + hive_generator 2.0.1 | 瑙佷笅 |
| 娴忚鍣ㄨ烦杞?| url_launcher | `^6.3.0` |
| 鍥剧墖鍔犺浇 | cached_network_image | `^3.4.1` |
| 鍏朵粬 | intl锛堟椂闂存牸寮忓寲锛夈€乸ath_provider | `^0.19.0` / `^2.1.4` |

Android 渚э紙`android/settings.gradle`銆乣android/app/build.gradle`锛?

| 缁勪欢 | 鐗堟湰 |
| --- | --- |
| Gradle / AGP / Kotlin | 8.7 / 8.6.0 / 1.9.24 |
| compileSdk / targetSdk / minSdk | 35 / 35 / 23 |
| Java source路target | 17锛圕odeMagic: `java: 17`锛?|
| applicationId / namespace | `com.wentianxia.news` |

> 鈿狅笍 **`freezed` 涓轰粈涔堥攣瀹?2.5.7**
> `hive_generator 2.0.1` 渚濊禆 `source_gen ^1.x`锛岃€?`freezed >= 2.5.8` 渚濊禆 `source_gen ^2.x`锛?> 浜岃€呮棤娉曞叡瀛橈紙`flutter pub get` 浼氱洿鎺ョ粰鍑?"version solving failed"锛夈€?> 鍥犳 `pubspec.yaml` 鐢?`freezed: 2.5.7` + `hive_generator: ^2.0.1`锛岃繖涔熸槸鑳藉悓鏃剁敓鎴?> `*.freezed.dart` 涓?`*.g.dart`锛圚ive Adapter锛夌殑鏈€浣庝唬浠锋柟妗堛€?
---

## 涓夈€佸揩閫熷紑濮?
> 鈿狅笍 **Windows 鐢ㄦ埛娉ㄦ剰锛氬伐绋嬭矾寰勫繀椤绘槸绾?ASCII銆?*
> 濡傛灉璺緞鍚腑鏂囷紙渚嬪 `D:\鏂囦欢\浠ｇ爜\...`锛夛紝`flutter build apk` 浼氬湪鏈€鍚庝竴姝ュけ璐ワ細
> * Dart AOT锛歚Unable to read file: D:\???\????\...\app.dill`
> * `impellerc`锛歚Could not write file to D:\?...\shaders/ink_sparkle.frag`
> 鍘熷洜鏄?AGP / Dart AOT / impellerc 鍦ㄤ腑鏂囦唬鐮侀〉涓嬪啓鏂囦欢浼氫涪瀛楃銆?> `android/gradle.properties` 閲岀殑 `android.overridePathCheck=true` 鍙兘娑堟帀 AGP 鐨?*璀﹀憡**锛?> 娑堜笉鎺夎繖涓や釜鐪熷疄鎶ラ敊銆備袱绉嶈В娉曪細
> 1. **鎶婂伐绋嬫斁鍒?ASCII 璺緞**锛堟帹鑽愶紝渚嬪 `D:\dev\wentianxia`锛夛紱
> 2. 澶嶅埗鍒?ASCII 璺緞鏋勫缓锛堜繚鐣欏師鐩綍锛夛細
>    ```powershell
>    robocopy "D:\鏂囦欢\浠ｇ爜\news\wentianxia" C:\wentianxia_build /E /XD build .dart_tool .git .gradle /XF local.properties
>    cd C:\wentianxia_build; flutter build apk --release
>    ```
> CodeMagic 鐨勬瀯寤烘満璺緞鏈韩灏辨槸 ASCII锛屼笉鍙楀奖鍝嶃€?
```bash
flutter --version    # 闇€ 3.27.x锛圖art 3.6.x锛?
# 1. 渚濊禆
flutter pub get

# 2. 浠ｇ爜鐢熸垚锛?.freezed.dart / *.g.dart锛涗粨搴撲腑宸叉彁浜ょ敓鎴愮粨鏋滐紝鍙烦杩囷級
dart run build_runner build --delete-conflicting-outputs

# 3. 闈欐€佹鏌?+ 娴嬭瘯
flutter analyze     # 鏈熸湜锛歂o issues found!
flutter test        # 鏈熸湜锛欰ll tests passed!锛?2 涓敤渚嬶級

# 4. 杩愯 / 鎵撳寘锛圓ndroid锛?flutter run
flutter build apk --release
# 浜х墿锛歜uild/app/outputs/flutter-apk/app-release.apk锛堢増鏈?1.0.1+2锛?```

棣栨鍚姩 App 鈫?绮樿创鑱氬悎鏁版嵁 API Key 鈫?閫夊叴瓒ｉ閬?鈫?杩涘叆鏂伴椈娴併€?锛圞ey 涔熷彲涔嬪悗鍦ㄣ€岃缃€嶄腑淇敼銆傦級

---

## 鍥涖€佺洰褰曠粨鏋?
```
lib/
鈹溾攢鈹€ main.dart                          # Hive 鍒濆鍖?鈫?ProviderScope 鈫?runApp
鈹溾攢鈹€ app.dart                           # MaterialApp.router锛圡aterial 3 / 娣辫壊涓婚锛?鈹溾攢鈹€ routes/
鈹?  鈹溾攢鈹€ app_router.dart                # go_router 閰嶇疆 + redirect锛堥鍚垽鏂級
鈹?  鈹斺攢鈹€ main_shell.dart                # 姣涚幓鐠?NavigationBar锛堟柊闂?/ 鏀惰棌锛?鈹溾攢鈹€ core/
鈹?  鈹溾攢鈹€ errors/news_api_exception.dart # 缁熶竴涓氬姟寮傚父
鈹?  鈹溾攢鈹€ services/share_service.dart    # 鍘熺敓鍒嗕韩 MethodChannel
鈹?  鈹溾攢鈹€ theme/app_theme.dart           # ColorScheme.fromSeed(deepPurple)
鈹?  鈹斺攢鈹€ widgets/
鈹?      鈹溾攢鈹€ blur_container.dart        # 楂樻柉妯＄硦瀹瑰櫒 / 姣涚幓鐠冩寜閽?/ BlurGroup
鈹?      鈹斺攢鈹€ news_network_image.dart    # CachedNetworkImage + placeholder + errorWidget
鈹溾攢鈹€ features/
鈹?  鈹溾攢鈹€ onboarding/
鈹?  鈹?  鈹溾攢鈹€ providers/onboarding_provider.dart   # 鍕鹃€夌姸鎬?+ 淇濆瓨鍒?Hive
鈹?  鈹?  鈹溾攢鈹€ views/onboarding_page.dart           # 涓ゆ寮曞椤?鈹?  鈹?  鈹斺攢鈹€ widgets/interest_selector.dart       # Chip 鍏磋叮閫夋嫨锛堟瘺鐜荤拑锛?鈹?  鈹溾攢鈹€ news/
鈹?  鈹?  鈹溾攢鈹€ data/news_channels.dart              # 14 涓閬擄紙type 鈫?涓枃鍚嶏級
鈹?  鈹?  鈹溾攢鈹€ models/news_article.dart             # Freezed + Hive锛? .freezed/.g锛?鈹?  鈹?  鈹溾攢鈹€ models/article_content.dart          # 鍏ㄦ枃椤靛唴瀹圭粨鏋?鈹?  鈹?  鈹溾攢鈹€ repositories/news_repository.dart    # 鑱氬悎鏁版嵁 API锛圞ey 浠?Hive 璇伙級
鈹?  鈹?  鈹溾攢鈹€ services/article_html_parser.dart    # 鍘熸枃姝ｆ枃鎶藉彇锛堥浂渚濊禆锛?鈹?  鈹?  鈹溾攢鈹€ providers/news_provider.dart         # 鏂伴椈娴佺姸鎬佹満
鈹?  鈹?  鈹斺攢鈹€ views/
鈹?  鈹?      鈹溾攢鈹€ news_feed_page.dart              # 涓绘粦鍔ㄩ〉锛堝瀭鐩?PageView锛?鈹?  鈹?      鈹溾攢鈹€ news_card.dart                   # 鍗曟潯鏂伴椈鍗＄墖
鈹?  鈹?      鈹斺攢鈹€ article_detail_page.dart         # 鍏ㄦ枃闃呰椤碉紙鑷姩婊氬姩锛?鈹?  鈹溾攢鈹€ favorites/
鈹?  鈹?  鈹溾攢鈹€ providers/favorites_provider.dart    # Hive watch 鈫?鑷姩鍒锋柊
鈹?  鈹?  鈹斺攢鈹€ views/favorites_page.dart            # 鏀惰棌鍒楄〃锛堝乏婊戝垹闄わ級
鈹?  鈹斺攢鈹€ settings/views/settings_page.dart        # 淇敼 Key / 鍏磋叮
鈹斺攢鈹€ shared/hive/
    鈹溾攢鈹€ hive_service.dart              # Hive 鍒濆鍖栦笌璇诲啓灏佽
    鈹溾攢鈹€ app_settings.dart              # API Key / 鍏磋叮 / 棣栧惎鏍囪锛坱ypeId 1锛?    鈹斺攢鈹€ settings_provider.dart         # 璁剧疆娴?+ 淇濆瓨鍔ㄤ綔
```

---

## 浜斻€佹灦鏋勪笌鏁版嵁娴?
閲囩敤 **MVVM + Riverpod**锛?
```
UI (View / ConsumerWidget)
      鈹? ref.watch / ref.read
      鈻?Provider / Notifier锛堢姸鎬佷笌涓氬姟缂栨帓锛?      鈹?      鈻?Repository锛圢ewsRepository / HiveService锛?      鈹溾攢鈹€ Dio  鈫?鑱氬悎鏁版嵁 https://v.juhe.cn/toutiao/index
      鈹斺攢鈹€ Hive 鈫?apiKey / selectedCategories / 鏀惰棌
      鈹?      鈻?妯″瀷锛圢ewsArticle / ArticleContent锛夆啋 鐘舵€佹洿鏂?鈫?UI 鑷姩閲嶅缓
```

涓夋潯鍏抽敭鏁版嵁娴侊細

| 娴佺▼ | 閾捐矾 |
| --- | --- |
| 鏂伴椈鍔犺浇 | `newsFeedControllerProvider.load()` 鈫?`NewsRepository.fetchArticles()` 鈫?璇?Hive 鐨?Key 鈫?Dio 璇锋眰 鈫?`NewsArticle` 鍒楄〃 鈫?`NewsFeedState` 鈫?`PageView` 閲嶅缓 |
| 鏀惰棌 | 蹇冨舰鎸夐挳 鈫?`favoritesProvider.toggle()` 鈫?`HiveService.toggleFavorite()` 鍐?`Box<NewsArticle>` 鈫?Box `watch()` 娴?鈫?`FavoritesController` 鏇存柊 鈫?鏀惰棌椤典笌鍗＄墖鍥炬爣鍚屾鍒锋柊 |
| 棣栨鍚姩 | `main()` 鍒濆鍖?Hive 鈫?`settingsProvider`锛坄StreamProvider`锛夆啋 `go_router.refreshListenable` 鈫?`redirect` 鍒ゆ柇 `isFirstLaunch / apiKey` |

---

## 鍏€佹牳蹇冨疄鐜拌瑙ｏ紙鍚唬鐮侊級

### 6.1 棣栨鍚姩鍒ゆ柇锛欻ive + go_router redirect

`lib/main.dart`锛圚ive 蹇呴』鍦?`runApp` 涔嬪墠鍒濆鍖栵紱鏈崟鑾峰紓甯稿厹搴曢伩鍏?release 鐧藉睆锛夛細

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) => FlutterError.presentError(details);
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('鏈崟鑾峰紓甯? $error');
    return true;
  };

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

  // Hive 钀藉湪搴旂敤绉佹湁鐩綍锛圓ndroid: /data/data/com.wentianxia.news/app_flutter锛?  await Hive.initFlutter('wentianxia_db');
  await HiveService.instance.init();

  runApp(
    ProviderScope(
      overrides: <Override>[hiveServiceProvider.overrideWithValue(HiveService.instance)],
      child: const WentianxiaApp(),
    ),
  );
}
```

`lib/routes/app_router.dart`锛堟妸璁剧疆鍙樺寲妗ユ帴鎴?`Listenable` 椹卞姩 redirect锛夛細

```dart
final Provider<GoRouterConfig> appRouterProvider = Provider<GoRouterConfig>((Ref ref) {
  final _SettingsNotifier listenable = _SettingsNotifier(ref);
  ref.onDispose(listenable.dispose);

  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,          // 鈫?Hive 璁剧疆涓€鍙樺氨閲嶇畻 redirect
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AppSettings> settingsAsync = ref.read(settingsProvider);
      if (settingsAsync.isLoading && !settingsAsync.hasValue) return null; // 鍚姩椤?
      final AppSettings? settings = settingsAsync.valueOrNull;
      // 棣栨鍚姩锛坕sFirstLaunch == true锛夋垨鏈～鍐?API Key 鈫?蹇呴』璧板紩瀵奸〉
      final bool needOnboarding = settings == null ||
          settings.isFirstLaunch || !settings.hasApiKey;

      final bool atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (needOnboarding) return atOnboarding ? null : AppRoutes.onboarding;
      if (atOnboarding || state.matchedLocation == AppRoutes.splash) return AppRoutes.news;
      return null;
    },
    routes: <RouteBase>[ /* splash / onboarding / settings / article / StatefulShellRoute */ ],
  );
  return GoRouterConfig(router: router, listenable: listenable);
});
```

### 6.2 寮曞椤碉細API Key 杈撳叆 + 鍏磋叮 Chip

`lib/features/onboarding/views/onboarding_page.dart`锛堥潪绌烘牎楠?+ 涓€閿矘璐达級锛?
```dart
BlurContainer(                                   // 楂樻柉妯＄硦鍖呰９杈撳叆妗?  borderRadius: BorderRadius.circular(18),
  blur: 10,
  opacity: 0.14,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  child: TextFormField(
    controller: _keyController,
    keyboardType: TextInputType.visiblePassword,
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      border: InputBorder.none,
      labelText: '鑱氬悎鏂伴椈API Key',
      hintText: '渚嬪锛歛1b2c3d4e5f6...',
      helperText: '鐢宠鍦板潃锛歫uhe.cn锛堟柊闂诲ご鏉?API锛屽厤璐?50 娆?澶╋級',
      prefixIcon: const Icon(Icons.vpn_key_outlined),
      suffixIcon: IconButton(                          // 涓€閿粠鍓创鏉跨矘璐?        tooltip: '绮樿创',
        icon: const Icon(Icons.content_paste),
        onPressed: () async {
          final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
          final String? text = data?.text?.trim();
          if (text == null || text.isEmpty) { _snack('鍓创鏉夸腑娌℃湁鏂囨湰'); return; }
          _keyController.text = text;
        },
      ),
    ),
    validator: (String? value) {
      if (value == null || value.trim().isEmpty) return 'API Key 涓嶈兘涓虹┖锛岃杈撳叆鑱氬悎鏁版嵁瀵嗛挜';
      if (value.trim().length < 8) return 'API Key 闀垮害杩囩煭锛岃妫€鏌ユ槸鍚﹀鍒跺畬鏁?;
      return null;
    },
  ),
)
```

鍏磋叮閫夋嫨锛堟瘡涓?`Chip` 澶栧眰閮芥槸楂樻柉妯＄硦瀹瑰櫒锛屾ā绯婂己搴︽寜棰戦亾鍝堝笇鍦?10~14 涔嬮棿寰皟褰㈡垚灞傛鎰燂級锛?
```dart
// lib/features/onboarding/widgets/interest_selector.dart
Wrap(
  spacing: 10,
  runSpacing: 10,
  children: channels.map((NewsChannel channel) {
    final bool isSelected = selected.contains(channel.type);
    final double sigma = 10 + (channel.type.hashCode % 5);
    return RepaintBoundary(
      child: BlurContainer(
        borderRadius: BorderRadius.circular(24),
        blur: sigma,
        opacity: isSelected ? 0.34 : 0.12,
        tint: isSelected ? colors.primary : colors.surface,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onToggle(channel.type),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(channel.icon), const SizedBox(width: 6), Text(channel.label),
                if (isSelected) ...<Widget>[const SizedBox(width: 6), const Icon(Icons.check_circle, size: 16)],
              ]),
            ),
          ),
        ),
      ),
    );
  }).toList(),
)
```

淇濆瓨鍒?Hive锛坄isFirstLaunch` 缃?false锛屽啓鍏?Key 涓庡叴瓒ｏ級锛?
```dart
// lib/features/onboarding/providers/onboarding_provider.dart
Future<bool> complete({required String apiKey}) async {
  final String key = apiKey.trim();
  if (key.isEmpty) { state = state.copyWith(error: 'API Key 涓嶈兘涓虹┖'); return false; }

  final Set<String> selected = state.selectedCategories.isEmpty
      ? <String>{kAllChannels.first.type}
      : state.selectedCategories;

  state = state.copyWith(saving: true, clearError: true);
  await _hive.completeOnboarding(apiKey: key, categories: selected.toList(growable: false));
  state = state.copyWith(saving: false, selectedCategories: selected);
  return true;
}
```

### 6.3 Hive 鏈湴瀛樺偍灏佽

`lib/shared/hive/hive_service.dart`锛堜笁涓?Box锛氳缃?/ 鏀惰棌 / 鍏冩暟鎹紱鍐欐搷浣滈兘 `flush()`锛夛細

```dart
class HiveService {
  static const String settingsBoxName  = 'wentianxia_settings';
  static const String favoritesBoxName = 'wentianxia_favorites';
  static const String metaBoxName      = 'wentianxia_meta';
  static const String settingsKey      = 'app_settings';

  late Box<AppSettings> settingsBox;
  late Box<NewsArticle> favoritesBox;
  late Box<dynamic> metaBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NewsArticleAdapter());

    settingsBox  = await Hive.openBox<AppSettings>(settingsBoxName);
    favoritesBox = await Hive.openBox<NewsArticle>(favoritesBoxName);
    metaBox      = await Hive.openBox<dynamic>(metaBoxName);

    if (settingsBox.get(settingsKey) == null) {
      await settingsBox.put(settingsKey, AppSettings());
    }
    _initialized = true;
  }

  /// 寮曞椤靛畬鎴愶細鍐?apiKey / selectedCategories 骞舵妸 isFirstLaunch 缃?false
  Future<AppSettings> completeOnboarding({
    required String apiKey, required List<String> categories,
  }) async {
    final AppSettings next = readSettings().copyWith(
      apiKey: apiKey.trim(),
      selectedCategories: List<String>.of(categories),
      isFirstLaunch: false,
      onboardingCompletedAt: DateTime.now(),
    );
    await saveSettings(next);
    return next;
  }

  /// 璇锋眰鏂伴椈鏃朵粠杩欓噷璇诲彇 API Key锛堜笉纭紪鐮佸湪浠讳綍鍦版柟锛?  String get apiKey => readSettings().apiKey.trim();

  /// 鏀惰棌 / 鍙栨秷鏀惰棌
  Future<bool> toggleFavorite(NewsArticle article) async {
    final int? existingKey = findFavoriteKey(article.key);
    if (existingKey != null) {
      await favoritesBox.delete(existingKey);
      await favoritesBox.flush();
      return false;
    }
    final NewsArticle stored = article.copyWith(favoritedAt: DateTime.now(), hiveKey: null);
    final int key = await favoritesBox.add(stored);
    await favoritesBox.put(key, stored.copyWith(hiveKey: key));
    await favoritesBox.flush();
    return true;
  }
}

/// main.dart 涓敤 HiveService.instance 瑕嗙洊
final Provider<HiveService> hiveServiceProvider = Provider<HiveService>(
  (Ref ref) => throw UnimplementedError('蹇呴』鍦?ProviderScope 涓鐩栦负 HiveService.instance'),
);
```

璁剧疆娴侊紙`StreamProvider` + Box `watch()`锛屼緵璺敱涓庤缃〉浣跨敤锛夛細

```dart
// lib/shared/hive/settings_provider.dart
final StreamProvider<AppSettings> settingsProvider = StreamProvider<AppSettings>((Ref ref) {
  final HiveService hive = ref.watch(hiveServiceProvider);

  Stream<AppSettings> watch() async* {
    yield hive.readSettings();                                  // 绔嬪嵆缁欏嚭褰撳墠鍊?    yield* hive.settingsBox.watch().map((BoxEvent _) => hive.readSettings());
  }

  return watch();
});
```

### 6.4 鏁版嵁妯″瀷锛欶reezed + Hive

`lib/features/news/models/news_article.dart`锛團reezed 鐢熸垚 `copyWith/==/toString`锛宧ive_generator 鐢熸垚 Adapter锛夛細

```dart
@HiveType(typeId: 2)
@freezed
class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    @HiveField(0) String? id,                                  // uniquekey / 鍏滃簳鍝堝笇
    @HiveField(1) @JsonKey(name: 'title') required String title,
    @HiveField(2) @JsonKey(name: 'author_name') @Default('') String author,
    @HiveField(3) @JsonKey(name: 'date') @Default('') String publishedAt,
    @HiveField(4) @JsonKey(name: 'thumbnail_pic_s') @Default('') String thumbnailUrl,
    @HiveField(5) @JsonKey(name: 'thumbnail_pic_s02') @Default('') String imageUrl2,
    @HiveField(6) @JsonKey(name: 'thumbnail_pic_s03') @Default('') String imageUrl3,
    @HiveField(7) @JsonKey(name: 'url') @Default('') String url,
    @HiveField(8) @JsonKey(name: 'category') @Default('top') String category,
    @HiveField(9) @JsonKey(name: 'description') @Default('') String summary,
    @HiveField(11) DateTime? favoritedAt,                      // 鏈敹钘?= null
    @HiveField(12) @JsonKey(includeFromJson: false, includeToJson: false) int? hiveKey,
  }) = _NewsArticle;

  const NewsArticle._();

  factory NewsArticle.fromJson(Map<String, dynamic> json) => _$NewsArticleFromJson(json);

  List<String> get images => <String>[thumbnailUrl, imageUrl2, imageUrl3]
      .where((String u) => u.trim().isNotEmpty).toList(growable: false);

  bool get hasImage => images.isNotEmpty;
  bool get isFavorite => favoritedAt != null;

  /// 绋冲畾鏍囪瘑锛氭帴鍙ｆ病鏈?id 鏃剁敤 url/鏍囬鍝堝笇锛堜繚璇佸悓涓€鏂伴椈涓嶄細閲嶅鏀惰棌锛?  String get key {
    final String raw = (id ?? '').trim();
    return raw.isNotEmpty ? raw : fallbackId(url, title);
  }

  /// 闇€姹傛潯鐩?5锛氱畝浠嬩负绌烘椂鎴彇姝ｆ枃鍓?200 瀛楃
  String defaultSummary([String? body]) {
    final String source = (body ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (source.isEmpty) {
      return '$title銆傛潵婧愶細${author.isEmpty ? '缃戠粶濯掍綋' : author}锛岀偣鍑汇€岃鐪嬪叏鏂囥€嶆煡鐪嬪畬鏁存姤閬撱€?;
    }
    return source.length <= 200 ? source : '${source.substring(0, 200)}鈥?;
  }

  static String fallbackId(String url, String title) =>
      'a${Object.hash(url.isEmpty ? title : url, title).abs()}';
}
```

鐢熸垚鐨?Hive Adapter锛坄news_article.g.dart`锛岃妭閫夛級锛?
```dart
class NewsArticleAdapter extends TypeAdapter<NewsArticle> {
  @override
  final int typeId = 2;

  @override
  NewsArticle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NewsArticle(
      id: fields[0] as String?, title: fields[1] as String, author: fields[2] as String,
      publishedAt: fields[3] as String, thumbnailUrl: fields[4] as String,
      imageUrl2: fields[5] as String, imageUrl3: fields[6] as String,
      url: fields[7] as String, category: fields[8] as String, summary: fields[9] as String,
      favoritedAt: fields[11] as DateTime?, hiveKey: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, NewsArticle obj) { /* ... 鎸夊瓧娈靛彿鍐欏叆 ... */ }
}
```

### 6.5 浠撳簱灞傦細浠?Hive 璇?Key 璇锋眰鑱氬悎鏁版嵁

`lib/features/news/repositories/news_repository.dart`锛?
```dart
const String kJuheToutiaoEndpoint = 'https://v.juhe.cn/toutiao/index';
const String kTheNewsApiEndpoint  = 'https://api.thenewsapi.com/v1/news/top';

Future<List<NewsArticle>> fetchArticles({List<String>? categories}) async {
  final String key = apiKey;                                  // 鈫?杩愯鏃朵粠 Hive 璇诲彇
  if (key.isEmpty) {
    throw const NewsApiException('灏氭湭閰嶇疆鑱氬悎鏂伴椈 API Key锛岃鍏堝畬鎴愬紩瀵艰缃€?);
  }

  final List<String> types = _resolveCategories(categories);

  // 澶囬€夋柟妗堬細Key 鍐欐垚 `thenewsapi:<token>` 鏃跺垏鎹㈡暟鎹簮
  if (key.toLowerCase().startsWith('thenewsapi:')) {
    final List<NewsArticle> alt =
        await _fetchTheNewsApi(key.substring('thenewsapi:'.length).trim(), types.first);
    await _hive.setLastRefresh(DateTime.now());
    return alt;
  }

  final List<List<NewsArticle>> results = <List<NewsArticle>>[];
  NewsApiException? lastError;
  for (final String type in types) {
    try {
      results.add(await _fetchJuhe(type, key));
    } on NewsApiException catch (e) {
      lastError = e;                                          // 鍗曢閬撳け璐ヤ笉鏁翠綋澶辫触
    }
  }
  if (results.isEmpty) {
    throw lastError ?? const NewsApiException('鏂伴椈鎺ュ彛鏆傛椂涓嶅彲鐢紝璇风◢鍚庨噸璇曘€?);
  }

  final List<NewsArticle> merged = _mergeInterleaved(results); // 澶氶閬撲氦鏇垮悎骞?  await _hive.setLastRefresh(DateTime.now());
  return merged;
}

Future<List<NewsArticle>> _fetchJuhe(String type, String key) async {
  final Response<dynamic> res = await _dio.get<dynamic>(
    kJuheToutiaoEndpoint,
    queryParameters: <String, dynamic>{
      'type': type, 'key': key, 'page': 1, 'page_size': 30, 'is_filter': 1,
    },
  );

  final Map<String, dynamic>? body = _asMap(res.data);
  final int? code = _asInt(body?['error_code']);
  if (code != 0) {
    throw NewsApiException(
      _friendlyMessage(code, body?['reason']?.toString() ?? '璇锋眰澶辫触'),
      code: code,
      isRateLimited: code == 10012 || code == 10001 || code == 10002,
    );
  }
  return _mapArticles(_asList(_asMap(body?['result'])?['data']), type);
}

/// 閿欒鐮?鈫?涓枃鎻愮ず
String _friendlyMessage(int? code, String reason) {
  switch (code) {
    case 10001: case 10002: case 10003: case 10004:
      return 'API Key 鏃犳晥鎴栧凡杩囨湡锛?reason锛夛紝璇峰埌銆岃缃€嶄腑閲嶆柊濉啓鑱氬悎鏁版嵁瀵嗛挜銆?;
    case 10012:
      return '浠婃棩鎺ュ彛璋冪敤娆℃暟宸茬敤瀹岋紙鍏嶈垂棰濆害 50 娆?澶╋級锛岃鏄庡ぉ鍐嶈瘯銆?;
    case 10020:
      return '鎺ュ彛缁存姢涓紝璇风◢鍚庡啀璇曘€?;
    default:
      return '鏂伴椈鑾峰彇澶辫触锛?reason';
  }
}

/// 棰戦亾鍘婚噸 + 鏈€澶?3 涓紙鎺у埗姣忔棩 50 娆″厤璐归搴︼級
List<String> _resolveCategories(List<String>? categories) {
  final List<String> source = (categories == null || categories.isEmpty)
      ? settings.effectiveCategories : categories;
  final Iterable<String> normalized =
      source.map<String>(normalizeChannelType).where((String t) => t.trim().isNotEmpty);
  final List<String> unique = normalized.toSet().toList(growable: false);
  return unique.isEmpty ? <String>['top'] : unique.take(3).toList();
}
```

瀛楁褰掍竴鍖栵細鍏煎鑱氬悎鏁版嵁涓庨潪鏍囧噯瀛楁鍚嶏紝骞舵妸 `id` / `category` 娉ㄥ叆鍚庡啀浜ょ粰 Freezed锛?
```dart
final Map<String, dynamic> normalized = <String, dynamic>{
  ...json,
  'category': type,
  'url':   (json['url'] ?? json['link'] ?? json['source_url'] ?? '').toString(),
  'title': (json['title'] ?? json['headline'] ?? '').toString(),
};
final String id = (json['uniquekey'] ?? json['uuid'] ?? json['id'])?.toString().trim()
    ?? NewsArticle.fallbackId(url, title);
normalized['id'] = id;
normalized['thumbnail_pic_s'] = (json['thumbnail_pic_s'] ?? json['image_url'] ?? json['image'] ?? '').toString();
normalized['author_name']     = (json['author_name'] ?? json['source'] ?? json['author'] ?? '').toString();
normalized['description']     = (json['description'] ?? json['snippet'] ?? json['summary'] ?? '').toString();
```

### 6.6 鏂伴椈娴侊細鍨傜洿 PageView + 涓婃粦鍒锋柊

`lib/features/news/providers/news_provider.dart`锛堢姸鎬佹満锛夛細

```dart
@immutable
class NewsFeedState {
  const NewsFeedState({
    this.articles = const <NewsArticle>[], this.currentIndex = 0,
    this.isLoading = false, this.isRefreshing = false, this.error,
  });

  final List<NewsArticle> articles;
  final int currentIndex;
  final bool isLoading, isRefreshing;
  final String? error;

  NewsArticle? get current =>
      (currentIndex >= 0 && currentIndex < articles.length) ? articles[currentIndex] : null;
}

class NewsFeedController extends StateNotifier<NewsFeedState> {
  NewsFeedController(this._ref) : super(const NewsFeedState()) { load(); } // 鏋勯€犲嵆鍔犺浇

  Future<void> load() async { /* 棣栧睆鍔犺浇锛堥鏋跺睆锛?*/ }
  Future<void> refresh() async { /* 涓嬫媺鍒锋柊锛氶噸鏂拌姹傛帴鍙?*/ }
  Future<void> loadCategory(String type, {bool keepCurrent = false}) async { /* 鍒囨崲棰戦亾 */ }
  void onPageChanged(int index) => state = state.copyWith(currentIndex: index);
}

final StateNotifierProvider<NewsFeedController, NewsFeedState> newsFeedControllerProvider =
    StateNotifierProvider<NewsFeedController, NewsFeedState>((Ref ref) => NewsFeedController(ref));
```

`lib/features/news/views/news_feed_page.dart`锛堜笂婊?涓嬫媺鍒锋柊 + 鍨傜洿 PageView锛夛細

```dart
/// 棣栨潯鏂伴椈缁х画涓嬫粦 鈫?瑙﹀彂鍒锋柊
bool _onScrollNotification(ScrollNotification notification) {
  if (notification.depth != 0) return false;
  if (notification is! OverscrollNotification) return false;   // 鍙瓒婄晫鎷栨嫿
  final bool pullingDown = notification.overscroll < 0;
  if (!pullingDown || _refreshTriggered) return false;
  if (_pageController.hasClients && _pageController.page != null) {
    if (_pageController.page!.round() != 0) return false;      // 浠呭湪绗竴鏉＄敓鏁?  }
  _refreshTriggered = true;
  _refresh();                                                  // 閲嶆柊璋冪敤 API
  return false;
}

// build 涓細
Positioned.fill(
  child: RefreshIndicator(
    onRefresh: _refresh,
    child: NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: _buildBody(state),
    ),
  ),
),

PageView.builder(
  controller: _pageController,
  scrollDirection: Axis.vertical,                              // 鈫?鐭棰戝紡涓婁笅鍒囨崲
  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
  itemCount: state.articles.length,
  onPageChanged: (int index) {
    _refreshTriggered = false;                                 // 鍥炲埌棣栨潯鍙啀娆¤Е鍙?    ref.read(newsFeedControllerProvider.notifier).onPageChanged(index);
  },
  itemBuilder: (BuildContext context, int index) => NewsCard(
    key: ValueKey<String>(state.articles[index].key),
    article: state.articles[index],
    index: index,
  ),
)
```

閿欒鎻愮ず涓庨噸璇曪紙`ref.listen` 鍙脊涓€娆?SnackBar锛夛細

```dart
ref.listen<String?>(
  newsFeedControllerProvider.select((NewsFeedState s) => s.error),
  (String? previous, String? next) {
    if (next != null && next != previous) {
      _showSnack(next);                                        // SnackBar + 銆岄噸璇曘€嶆寜閽?      ref.read(newsFeedControllerProvider.notifier).consumeError();
    }
  },
);
```

### 6.7 鍗曟潯鏂伴椈鍗＄墖甯冨眬

`lib/features/news/views/news_card.dart`锛堝浘鐗?38% 灞忛珮 鈫?鏍囬 鈫?绠€浠?鈫?姣涚幓鐠冩寜閽?+ 鏀惰棌锛夛細

```dart
final double imageHeight = MediaQuery.sizeOf(context).height * 0.38;

Stack(fit: StackFit.expand, children: <Widget>[
  Hero(
    tag: 'article-image-${article.key}',
    child: NewsNetworkImage(url: article.thumbnailUrl, height: imageHeight, fallbackSeed: index),
  ),
  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      stops: const <double>[0, 0.28, 0.55, 1],
      colors: <Color>[Colors.black54, Colors.black12, Colors.black, Colors.black]),
  ))),
  Positioned(left: 0, right: 0, bottom: 0, child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),           // 搴曢儴鐣欏嚭瀵艰埅鏍忛珮搴?    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CategoryTag(channel: channel, publishedAt: article.publishedAt),
        const SizedBox(height: 12),
        Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis,
             style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
        const SizedBox(height: 10),
        // 鏉ユ簮琛?...
        Text(article.displaySummary, maxLines: 3, overflow: TextOverflow.ellipsis,
             style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
        const SizedBox(height: 18),
        Row(children: <Widget>[
          BlurButton(
            label: '瑙傜湅鍏ㄦ枃', icon: Icons.menu_book_outlined, opacity: 0.2,
            foregroundColor: Colors.white,
            onPressed: () => context.push('${AppRoutes.article}?id=${article.key}', extra: article),
          ),
          const Spacer(),
          _RoundIconButton(                                       // 鏀惰棌蹇冨舰锛堟瘺鐜荤拑鍦嗛挳锛?            icon: favorite ? Icons.favorite : Icons.favorite_border,
            color: favorite ? const Color(0xFFFF5C8A) : Colors.white,
            onPressed: () => _toggleFavorite(context, ref),
          ),
        ]),
      ]),
  )),
])
```

### 6.8 鍏ㄦ枃闃呰锛氳繃娓″姩鐢?+ 鑷姩婊氬姩

璺敱杩囨浮锛坄lib/routes/app_router.dart`锛宍CustomTransitionPage` + Fade/Slide锛夛細

```dart
GoRoute(
  path: AppRoutes.article,
  name: 'article',
  pageBuilder: (BuildContext context, GoRouterState state) {
    final NewsArticle? article = state.extra is NewsArticle ? state.extra! as NewsArticle : null;
    return CustomTransitionPage<void>(
      key: state.pageKey,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      child: ArticleDetailPage(article: article, articleId: state.uri.queryParameters['id']),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(opacity: curved, child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
          child: child));
      },
    );
  },
)
```

鑷姩婊氬姩锛坄lib/features/news/views/article_detail_page.dart`锛屽熀鍑?40px/s锛屽洓妗ｉ€熷害锛屽埌搴曡嚜鍋滐級锛?
```dart
static const double _basePixelsPerTick = 1.0;   // 姣?25ms 1px 鈮?40px/s
static const int _tickMs = 25;
double _speedMultiplier = 1.0;                  // 0.5 / 1.0 / 1.5 / 2.0

/// 棣栧抚娓叉煋瀹屾垚鍚庡啀鍚姩鑷姩婊氬姩锛堟鏃舵粴鍔ㄨ寖鍥存墠鍙敤锛?void _scheduleAutoScroll() {
  if (_autoScrollTimer != null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _autoScrollTimer == null) _startAutoScroll();
  });
}

void _startAutoScroll() {
  _autoScrollTimer?.cancel();
  _autoScrollTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
    if (!_scrollController.hasClients) return;
    final double max = _scrollController.position.maxScrollExtent;
    final double next = _scrollController.offset + _basePixelsPerTick * _speedMultiplier;
    if (next >= max) { _scrollController.jumpTo(max); _stopAutoScroll(); return; }
    _scrollController.jumpTo(next);
  });
  if (mounted) setState(() => _autoScrollEnabled = true);
}

void _cycleSpeed() {
  const List<double> speeds = <double>[0.5, 1.0, 1.5, 2.0];
  final int index = speeds.indexOf(_speedMultiplier);
  setState(() => _speedMultiplier = speeds[(index + 1) % speeds.length]);
}
```

搴曢儴鎿嶄綔鏍忥紙姣涚幓鐠?+ `url_launcher` + 鏀惰棌 + 鍒嗕韩锛夛細

```dart
Future<void> _openOriginal(NewsArticle article) async {
  final Uri? uri = Uri.tryParse(article.url.trim());
  if (uri == null || !uri.hasScheme) { _snack('杩欐潯鏂伴椈娌℃湁鍙敤鐨勫師鏂囬摼鎺?); return; }
  try {
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack('鏈兘鎵撳紑娴忚鍣紝璇风◢鍚庨噸璇?);
  } on Object { _snack('鏈兘鎵撳紑娴忚鍣紝璇风◢鍚庨噸璇?); }
}
```

### 6.9 姝ｆ枃鎶藉彇锛欰rticleHtmlParser

鍏ㄦ枃椤靛唴瀹规潵婧愶細**浼樺厛鎶撳彇鍘熸枃 HTML**锛屽け璐ユ垨瀛楁暟涓嶈冻鍒欓€€鍖栦负銆屾憳瑕佹ā寮忋€嶏紙淇濊瘉姘歌繙鏈夊唴瀹瑰彲璇伙級銆?
```dart
// lib/features/news/repositories/news_repository.dart
Future<ArticleContent> fetchArticleContent(NewsArticle article) async {
  final String url = article.url.trim();
  if (url.isEmpty) return _fallbackContent(article);

  final ArticleContent? cached = _htmlCache[url];               // 鍐呭瓨 LRU锛?4 鏉★級
  if (cached != null) return cached;

  try {
    final Response<String> res = await _htmlDio.get<String>(url);
    final ArticleContent parsed =
        ArticleHtmlParser.parse(res.data ?? '', fallbackTitle: article.title);
    if (parsed.charCount >= 160) {                              // 瀛楁暟闂ㄦ
      final ArticleContent content = parsed.copyWith(
        title: parsed.title.isEmpty ? article.title : parsed.title,
        source: parsed.source.isEmpty ? article.author : parsed.source,
        author: article.author, publishedAt: article.publishedAt,
        images: _mergeImages(parsed.images, article.images),
      );
      _remember(url, content);
      return content;
    }
  } on Object catch (e) { debugPrint('鍘熸枃鎶撳彇澶辫触($url): $e'); }

  final ArticleContent fallback = _fallbackContent(article);
  _remember(url, fallback);
  return fallback;
}
```

鎶藉彇绛栫暐锛堥浂绗笁鏂逛緷璧栵紝`lib/features/news/services/article_html_parser.dart`锛夛細

1. 鍘绘帀 `script/style/nav/footer/header/form/svg/iframe/aside` 绛夊櫔澹板潡涓庢敞閲婏紱
2. 姝ｆ枃瀹瑰櫒锛歚<article>` 鎴?`id/class` 鍛戒腑 `article-content | content-body | news-content | main-content | post-content | rich_media | detail-content | content` 鐨?`div/section`锛?3. 瀹瑰櫒鍐呮敹闆?`<p>`锛堥暱搴?鈮?12锛変笌 `<img src|data-src|data-original>`锛涙枃鏈笉瓒虫椂閫€鍖栦负銆屾暣椤垫渶闀挎枃鏈潡銆嶏紱
4. 鏍囬锛歚og:title` 鈫?`<h1>` 鈫?`<title>`锛坄<meta>` 灞炴€ч『搴忎笉鍥哄畾锛岄€愪釜鏍囩瑙ｆ瀽 `property`/`content`锛夛紱
5. 鍙嶈浆涔夛紙`&nbsp; &#39; &#x27;` 鈥︼級+ 鍘嬬缉绌虹櫧銆?
```dart
static final String _q  = '["\']';        // 寮曞彿瀛楃绫?static final String _qv = '[^"\']';       // 灞炴€у€硷紙涓嶈法寮曞彿锛?static final RegExp _metaTag    = RegExp('<meta\\b[^>]*>', caseSensitive: false);
static final RegExp _propertyAttr = RegExp('property\\s*=\\s*$_q($_qv+)', caseSensitive: false);
static final RegExp _contentAttr  = RegExp('content\\s*=\\s*$_q($_qv+)', caseSensitive: false);
static final RegExp _noiseBlock = RegExp(
  r'<(script|style|noscript|nav|footer|header|form|svg|iframe|aside)\b[^>]*>.*?</\1>',
  caseSensitive: false, dotAll: true);

/// 璇诲彇 <meta property="..." content="...">锛堜袱绉嶅睘鎬ч『搴忛兘鏀寔锛?static String? _metaContent(String html, String property) {
  for (final RegExpMatch m in _metaTag.allMatches(html)) {
    final String tag = m.group(0) ?? '';
    final String? prop = _firstGroup(_propertyAttr, tag);
    if (prop == null || prop.trim().toLowerCase() != property) continue;
    final String? content = _firstGroup(_contentAttr, tag);
    if (content != null) return content;
  }
  return null;
}
```

### 6.10 鏀惰棌锛欻ive Box + 宸︽粦鍒犻櫎

`lib/features/favorites/providers/favorites_provider.dart`锛圚ive 鐨?`watch()` 娴侀┍鍔ㄨ嚜鍔ㄥ埛鏂帮級锛?
```dart
class FavoritesController extends StateNotifier<List<NewsArticle>> {
  FavoritesController(this._hive) : super(_hive.favorites()) {
    _sub = _hive.favoritesBox.watch().listen((BoxEvent _) {   // 鈫?浠讳綍鍐欏叆閮戒細閫氱煡
      if (mounted) state = _hive.favorites();
    });
  }

  Future<bool> toggle(NewsArticle article) async {
    final bool favorite = await _hive.toggleFavorite(article);
    state = _hive.favorites();
    return favorite;
  }

  Future<void> remove(NewsArticle article) async { /* 宸︽粦鍒犻櫎 */ }
  Future<void> clearAll() async { /* 娓呯┖ */ }

  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

/// 鏌愭潯鏂伴椈鏄惁宸叉敹钘忥紙灞€閮ㄥ埛鏂帮紝閬垮厤鏁撮〉閲嶅缓锛?final ProviderFamily<bool, String> isFavoriteProvider =
    Provider.family<bool, String>((Ref ref, String id) =>
        ref.watch(favoritesProvider).any((NewsArticle a) => a.key == id));
```

鏀惰棌椤碉紙`Dismissible` 宸︽粦鍒犻櫎 + 鎾ら攢 + 绌虹姸鎬侊級锛?
```dart
Dismissible(
  key: ValueKey<String>('fav-${article.key}'),
  direction: DismissDirection.endToStart,
  background: _dismissBackground(theme),
  onDismissed: (_) => _remove(context, ref, article),
  child: _FavoriteTile(article: article),   // 缂╃暐鍥?+ 鏍囬 + 鏀惰棌鏃堕棿
)

// 绌虹姸鎬?BlurContainer(
  borderRadius: BorderRadius.circular(28), blur: 10, opacity: 0.14,
  padding: const EdgeInsets.all(26),
  child: Icon(Icons.bookmark_border, size: 54, color: theme.colorScheme.primary),
),
Text('杩樻病鏈夋敹钘忕殑鏂伴椈', style: theme.textTheme.titleMedium),
```

### 6.11 楂樻柉妯＄硦瑙勮寖锛圔lurContainer锛?
`lib/core/widgets/blur_container.dart` 鈥斺€?鍏ㄧ珯姣涚幓鐠冪殑鍞竴瀹炵幇鍏ュ彛銆?
**鈿狅笍 鍏抽敭绾︽潫锛?.0.1 淇锛?*锛歚ClipRRect` 涓?`BackdropFilter` 涔嬮棿銆?浠ュ強 `BackdropFilter` 鐨勬暣鏉＄鍏堥摼涓婏紝**涓嶅厑璁稿嚭鐜?`RepaintBoundary`**锛?鍚﹀垯 backdrop 閲囨牱鑼冨洿浼氳鎴柇锛屽嚭鐜板浘鍍忕己澶辫壊甯︿笌婊戝姩闂儊锛堣瑙佸紑澶淬€岀増鏈褰曘€嶏級銆?
```dart
// lib/core/widgets/blur_container.dart锛?.0.1 姝ｇ‘褰㈡€侊級
return ClipRRect(                                   // 鈶?灞€閮ㄨ鍓紝妯＄硦涓嶅婧?  borderRadius: borderRadius ?? BorderRadius.zero,
  clipBehavior: clipBehavior,
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 鈶?楂樻柉妯＄硦 蟽=10
    child: Container(                                // 鈶?child 蹇呴』鏄彲瑙佸鍣?      width: width, height: height, alignment: alignment,
      padding: padding, margin: margin,
      decoration: BoxDecoration(
        color: baseTint.withValues(alpha: opacity),   // 鍗婇€忔槑搴曡壊锛氳妯＄硦鐪嬪緱瑙?        borderRadius: borderRadius,
        border: border ?? Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35), width: 0.8),
      ),
      child: child,
    ),
  ),
);
// 娉ㄦ剰锛氳繖閲屽埢鎰忎笉鍖?RepaintBoundary锛堝師鍥犺 1.0.1 淇璇存槑锛?```

閰嶅鐨勪笁涓粍浠讹紙鍚屼竴涓枃浠讹級锛?
| 缁勪欢 | 浣滅敤 | 鍏抽敭鐐?|
| --- | --- | --- |
| `GlassBackdrop` | 椤甸潰鏈€搴曞眰閾哄叏灞忔笎鍙?| 淇濊瘉姣涚幓鐠冧笅鏂?*姘歌繙鏈夊凡缁樺埗鍍忕礌**锛屽唴瀹逛笉瓒充竴灞忎篃涓嶄細鍑虹幇绌虹櫧甯?|
| `GlassTint` | 闈欐€佸崐閫忔槑濉厖 | 鐢ㄤ簬**宸插湪妯＄硦鏉″唴閮?*鐨勬寜閽紝涓嶅啀鍙犲姞 backdrop 灞傦紙閬垮厤澶氬眰閲囨牱鑹插甫/闂儊锛?|
| `BlurBar` | 椤?搴曟偓娴瘺鐜荤拑鏉?| 鏁存潯鍙仛涓€娆℃ā绯婏紝`Clip.hardEdge` 鐭╁舰瑁佸壀 + 鑷畾涔夊唴杈硅窛 |

姣涚幓鐠冩寜閽紙鍗＄墖銆岃鐪嬪叏鏂囥€嶃€侀敊璇噸璇曘€佸紩瀵奸〉銆屽墠寰€鑱氬悎鏁版嵁鐢宠銆嶇瓑閮界敤瀹冿紱
`flat: true` 鏃惰嚜鍔ㄩ檷绾т负 `GlassTint`锛岀敤浜庢ā绯婃潯鍐呴儴锛夛細

```dart
// lib/core/widgets/blur_container.dart
Widget button = flat
    ? GlassTint(                       // 妯＄硦鏉″唴閮細闈欐€佸～鍏咃紝闆?backdrop 灞?        borderRadius: borderRadius,
        opacity: opacity + 0.04,
        tint: theme.colorScheme.surface,
        child: inner,
      )
    : BlurContainer(                   // 鐙珛鎺т欢锛氱湡姝ｇ殑 BackdropFilter 妯＄硦
        borderRadius: borderRadius,
        blur: blur,
        opacity: opacity,
        child: inner,
      );
```

椤甸潰绾х敤娉曪紙涓夊眰缁撴瀯锛屼笁灞傝亴璐ｅ垎鏄庯級锛?
```dart
// lib/features/news/views/news_feed_page.dart
Scaffold(
  backgroundColor: Colors.black,
  body: Stack(children: <Widget>[
    const GlassBackdrop(                                  // 鈶?鍏滃簳鐜荤拑搴?      colors: <Color>[Color(0xFF141118), Color(0xFF0A0A0D), Color(0xFF171226)],
    ),
    Positioned.fill(child: RefreshIndicator(              // 鈶?閲囨牱婧愶細鏁村睆鍐呭
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: _buildBody(state),
      ),
    )),
    Positioned(top: 0, left: 0, right: 0,                 // 鈶?椤堕儴姣涚幓鐠冧俊鎭爮
      child: _TopBar(...)),
  ]),
)
```

妯＄硦鎺т欢瑕嗙洊鑼冨洿锛氶€氱敤瀹瑰櫒銆佹寜閽紙瑙傜湅鍏ㄦ枃 / 閲嶈瘯 / 闃呰鍘熸枃 / 涓婁竴姝?/ 鍓嶅線鑱氬悎鏁版嵁鐢宠锛夈€?椤堕儴鍒锋柊涓庤缃浘鏍囬挳銆佹敹钘忓績褰㈤挳銆佸簳閮?`NavigationBar`銆佸叏鏂囬〉椤堕儴杩涘害鏉′笌搴曢儴鎿嶄綔鏍忋€?棰戦亾鍒囨崲寮圭獥銆佸叴瓒?`Chip`銆佹敹钘忓崱鐗囥€佺┖鐘舵€佸崰浣嶃€?
**鍏充簬 `BackdropGroup` / `BackdropFilter.grouped()`**锛氳 API 鑷?**Flutter 3.35** 璧锋墠鍙敤锛?鏈」鐩攣瀹?CodeMagic 涓婇獙璇佽繃鐨?3.27.4锛屽洜姝?`BlurGroup` 鐩墠鏄?*闆跺紑閿€鐨勮涔夊寲鍒嗙粍瀹瑰櫒**銆?鍗囩骇鍒?3.35+ 鍚庡彧闇€涓€澶勬浛鎹紙鍙涓€缁勬ā绯婃帶浠跺叡浜悓涓€娆¤儗鏅噰鏍凤紝杩涗竴姝ョ渷 GPU锛夛細

```dart
class BlurGroup extends StatelessWidget {
  const BlurGroup({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);  // 鈫?鏀逛负杩欎竴琛?}
```

### 6.11.1 姣涚幓鐠冪殑灞傜粨鏋勮鍒欙紙鍔″繀閬靛畧锛?
| 瑙勫垯 | 璇存槑 |
| --- | --- |
| 鉁?鍏佽 | `ClipRRect/ClipRect` 鈫?`BackdropFilter` 鈫?`Container`锛堝彲瑙佽楗扮洅锛?|
| 鉂?绂佹 | `RepaintBoundary` 鍑虹幇鍦?`BackdropFilter` 鐨勭鍏堥摼涓婏紙鎴柇 backdrop 閲囨牱锛?|
| 鉂?绂佹 | 涓€鏉?bar 鍐呭祵濂楀涓?`BackdropFilter`锛堝灞?backdrop 鈫?鑹插甫/闂儊/GPU 缈诲€嶏級 |
| 鉁?鎺ㄨ崘 | 闇€瑕侀殧绂婚噸缁樻椂锛屾妸 `RepaintBoundary` 鍖呭湪**鏁村潡婊氬姩鍐呭**鐨勪笂涓€灞?|
| 鉁?蹇呴』 | 姣忎釜鐣岄潰鐢?`GlassBackdrop` 閾轰竴灞傚叏灞忓簳锛堟ā绯婁笅鏂规案杩滄湁鍍忕礌锛?|

鍥炲綊娴嬭瘯浼氳嚜鍔ㄦ鏌ュ墠涓ゆ潯锛歚test/blur_regression_test.dart`銆?
### 6.12 Material 3 涓婚

`lib/core/theme/app_theme.dart`锛?
```dart
static const Color seedColor = Color(0xFF6750A4);   // Material 3 榛樿 deepPurple 绯?
static ThemeData get dark {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: seedColor, brightness: Brightness.dark);
  return _base(scheme);
}

static ThemeData _base(ColorScheme scheme) => ThemeData(
  useMaterial3: true,
  colorScheme: scheme,
  chipTheme: ChipThemeData(
    backgroundColor: Colors.transparent,
    selectedColor: scheme.primary.withValues(alpha: 0.45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.transparent, elevation: 0, height: 66,
    indicatorColor: scheme.primary.withValues(alpha: 0.35),
  ),
  filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w700, height: 1.25),
    bodyMedium: TextStyle(height: 1.5), bodyLarge: TextStyle(height: 1.7, fontSize: 17)),
);
```

搴曢儴 Tab 鐢?Material 3 `NavigationBar`锛坄StatefulShellRoute.indexedStack` 淇濈暀鍚?Tab 鐘舵€侊級锛?
```dart
// lib/routes/main_shell.dart
Scaffold(
  extendBody: true,                              // 鍐呭寤朵几鍒板鑸爮涔嬩笅锛屾瘺鐜荤拑鎵嶆湁鑳屾櫙鍙噰鏍?  body: shell,
  bottomNavigationBar: RepaintBoundary(child: ClipRect(child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(color: scheme.surface.withValues(alpha: 0.30),
      child: SafeArea(top: false, child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: '鏂伴椈'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: '鏀惰棌'),
        ]))))),
)
```

### 6.13 鍘熺敓鍒嗕韩 MethodChannel

Dart 渚э紙`lib/core/services/share_service.dart`锛屼笉寮曞叆绗笁鏂规彃浠讹紝闄嶄綆 CI 椋庨櫓锛夛細

```dart
class ShareService {
  static const MethodChannel _channel = MethodChannel('com.wentianxia.wentianxia/share');

  static Future<bool> shareText({required String title, required String text}) async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'shareText', <String, String>{'title': title, 'text': text});
      return ok ?? false;
    } on PlatformException { return false; }
      on MissingPluginException { return false; }
  }
}
```

Android 渚э紙`android/app/src/main/kotlin/com/wentianxia/news/MainActivity.kt`锛夛細

```kotlin
class MainActivity : FlutterActivity() {
    private companion object { const val SHARE_CHANNEL = "com.wentianxia.wentianxia/share" }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> result.success(
                        shareText(call.argument<String>("title") ?: "闂诲ぉ涓?,
                                  call.argument<String>("text") ?: ""))
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareText(title: String, text: String): Boolean = try {
        startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, title)
            putExtra(Intent.EXTRA_TEXT, text)
        }, "鍒嗕韩鍒?).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) { false }
}
```

Android 鏉冮檺涓庡閮ㄨ烦杞０鏄庯紙`android/app/src/main/AndroidManifest.xml`锛夛細

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<application android:label="@string/app_name" ...>

<!-- url_launcher 鍦?Android 11+ 闇€瑕佸０鏄庡彲鏌ヨ鐨勫閮?Activity -->
<queries>
    <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
    <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="http"/></intent>
    <intent><action android:name="android.intent.action.SEND"/><data android:mimeType="text/plain"/></intent>
    <intent><action android:name="android.intent.action.PROCESS_TEXT"/><data android:mimeType="text/plain"/></intent>
</queries>
```

---

## 涓冦€佽仛鍚堟暟鎹?API 璇存槑

1. 璁块棶 <https://www.juhe.cn/docs/api/id/235> 娉ㄥ唽骞剁敵璇枫€屾柊闂诲ご鏉°€嶆帴鍙ｏ紱
2. 鍦ㄤ釜浜轰腑蹇冨鍒?API Key锛?3. 棣栨鍚姩 App 鏃剁矘璐村埌寮曞椤碉紙鎴栦箣鍚庡湪銆岃缃€嶉噷淇敼锛夈€?
| 椤圭洰 | 璇存槑 |
| --- | --- |
| 鎺ュ彛 | `https://v.juhe.cn/toutiao/index` |
| 鍙傛暟 | `type`锛堥閬擄級銆乣key`锛?*鏉ヨ嚜 Hive**锛夈€乣page`銆乣page_size`銆乣is_filter` |
| 鍏嶈垂棰濆害 | 50 娆?澶?鈫?棣栭〉鏈€澶氬苟鍙戣姹?3 涓閬擄紙`unique.take(3)`锛?|
| 棰戦亾 | 澶存潯 `top`銆佸浗鍐?`guonei`銆佸浗闄?`guoji`銆佸ū涔?`yule`銆佷綋鑲?`tiyu`銆佸啗浜?`junshi`銆佺鎶€ `keji`銆佽储缁?`caijing`銆佹父鎴?`youxi`銆佹苯杞?`qiche`銆佸仴搴?`jiankang`銆佹椂灏?`shishang`銆佹暀鑲?`jiaoyu`銆佹梾娓?`lvyou` |
| 瀛楁鏄犲皠 | `title`鈫抈title`銆乣author_name`鈫抈author`銆乣thumbnail_pic_s`鈫抈thumbnailUrl`銆乣url`鈫抈url`銆乣date`鈫抈publishedAt`銆乣description`鈫抈summary`銆乣uniquekey`鈫抈id` |
| 澶囬€夋柟妗?| Key 鍐欐垚 `thenewsapi:<token>` 鈫?鑷姩鏀圭敤 `https://api.thenewsapi.com/v1/news/top?api_token=鈥?language=zh&limit=30` |

---

## 鍏€丆odeMagic 鏋勫缓

褰撳墠鐗堟湰 **1.0.1+2**锛坴ersionCode 2锛夈€備粨搴撴牴鐩綍宸插寘鍚?`codemagic.yaml`锛?
```yaml
workflows:
  wentianxia-android:
    name: 闂诲ぉ涓?Android Build
    max_build_duration: 60
    instance_type: mac_mini_m2
    environment:
      flutter: 3.27.4      # 涓庢湰鍦伴獙璇佺増鏈竴鑷?      java: 17             # AGP 8.6 / Gradle 8.7 瑕佹眰 JDK 17
    cache:
      cache_paths:
        - $FLUTTER_ROOT/.pub-cache
        - $HOME/.gradle/caches
    scripts:
      - name: Flutter packages
        script: flutter pub get
      - name: Static analysis
        script: flutter analyze
      - name: Unit tests
        script: flutter test
      - name: Build release APKs
        script: flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/app-release.apk
      - build/app/outputs/flutter-apk/*.apk
      - build/app/outputs/**/*.aab
```

浣跨敤姝ラ锛氭妸鏈粨搴撹繛鍒?CodeMagic 鈫?閫夋嫨 `wentianxia-android` 宸ヤ綔娴?鈫?Start new build銆?鏋勫缓鍓嶈鎶?`publishing.email.recipients` 鐨勫崰浣嶉偖绠辨敼鎴愯嚜宸辩殑锛屾垨鍒犻櫎鏁存 `publishing`銆?
**涓恒€屼笉鎶ラ敊銆嶅仛鐨勫伐绋嬬害鏉?*

| 绾︽潫 | 鍘熷洜 |
| --- | --- |
| `flutter: 3.27.4` + `java: 17` 鍥哄畾 | 閬垮厤 CI 浣跨敤鏈€鏂?Flutter/Java 瀵艰嚧 API 鎴?Gradle 鍏煎闂 |
| AGP 8.6.0 / Gradle 8.7 / Kotlin 1.9.24 | 涓?Flutter 3.27.4 瀹樻柟鏀寔鐨勭粍鍚堜竴鑷?|
| `freezed: 2.5.7`锛堥潪 caret 鑼冨洿锛?| 瑙勯伩 `source_gen ^1 vs ^2` 鐨勪緷璧栧啿绐?|
| `*.freezed.dart` / `*.g.dart` 宸叉彁浜?| CI 鏃犻渶杩愯 build_runner锛屽皯涓€涓け璐ョ偣 |
| `android/.gitignore` 涓嶅啀蹇界暐 `gradle-wrapper.jar`/`gradlew` | 鍚﹀垯 CI 缂哄皯 Gradle wrapper 鏃犳硶鏋勫缓 |
| Gradle 閰嶇疆娉ㄩ噴淇濇寔 ASCII | 閬垮厤涓嶅悓骞冲彴榛樿缂栫爜锛圙BK/UTF-8锛夎В鏋愰棶棰?|
| 鍒嗕韩鍔熻兘鐢ㄥ師鐢?MethodChannel | 涓嶅紩鍏ラ澶栨彃浠讹紝鍑忓皯 Android 渚х紪璇戦闄?|
| release 浣跨敤 debug 绛惧悕 | 淇濊瘉 `flutter build apk --release` 鐩存帴浜у嚭鍙畨瑁呭寘锛堝彂甯冨墠鏇挎崲 keystore锛?|

---

## 涔濄€佹祴璇?
`test/widget_test.dart` 鍏?8 涓敤渚嬶紝瑕嗙洊鏈湴瀛樺偍銆佹鏂囨娊鍙栦笌妯″瀷閫昏緫锛?
```bash
flutter test
# 00:01 +12: All tests passed!
```

`test/widget_test.dart`锛? 涓敤渚嬶級鈥斺€?鏈湴瀛樺偍 / 姝ｆ枃鎶藉彇 / 妯″瀷閫昏緫锛?
| 鐢ㄤ緥 | 鏍￠獙鐐?|
| --- | --- |
| 寮曞椤典繚瀛?API Key / 鍏磋叮绫诲埆 | Key 鍘荤┖鏍煎啓鍏ャ€乣isFirstLaunch=false`銆侀噸鏂拌鍙栵紙妯℃嫙涓嬫鍚姩锛変粛鏈夋晥 |
| 鏀惰棌鍐欏叆 / 鍙栨秷鏀惰棌 | Hive Box 涓褰曞鍒犮€乣isFavorite` 鐘舵€併€侀噸澶?toggle 骞傜瓑 |
| HTML 鍏ㄦ枃鎶藉彇 | `<p>` 娈佃惤銆佹鏂囧浘鐗囥€乣og:title`/`og:site_name`銆佸櫔澹板潡锛坄nav`锛夎鍓旈櫎 |
| 绌?HTML 鍏滃簳 | 杩斿洖 fallbackTitle 鑰屼笉宕╂簝 |
| 鑱氬悎鏁版嵁 JSON 鍙嶅簭鍒楀寲 | `author_name/description/thumbnail_pic_s` 鏄犲皠姝ｇ‘ |
| 绠€浠嬩负绌烘埅鍙?200 瀛楃 | `defaultSummary` 闀垮害 201锛?00 + 鐪佺暐鍙凤級 |
| `url` 涓虹┖鏃剁殑绋冲畾 id | 鍚屼竴鏍囬涓ゆ鐢熸垚鐩稿悓鍝堝笇 id |
| Material 3 娓叉煋鍐掔儫 | `useMaterial3: true` 涓嬪熀纭€缁勪欢姝ｅ父鏋勫缓 |

`test/blur_regression_test.dart`锛? 涓敤渚嬶級鈥斺€?**1.0.1 姣涚幓鐠冨眰缁撴瀯鍥炲綊娴嬭瘯**锛?
| 鐢ㄤ緥 | 鏍￠獙鐐?|
| --- | --- |
| `BlurContainer` 灞傜粨鏋?| 蹇呴』鍚?`BackdropFilter` + `ClipRRect`锛屼笖鍐呴儴**涓嶅惈** `RepaintBoundary` |
| `BackdropFilter` 绁栧厛閾?| 绁栧厛閾句笂涓嶅厑璁稿嚭鐜?`RepaintBoundary`锛堣 bug 鐨勬牴鍥狅級 |
| `BlurButton` 涓ょ褰㈡€?| 鏅€氬舰鎬佷骇鐢?backdrop 灞傦紱`flat: true` 褰㈡€佷笉浜х敓锛堢敤浜庢ā绯婃潯鍐呴儴锛?|
| `GlassBackdrop` / `GlassTint` | 鍏滃簳搴曢摵婊″叏灞忎笖缁樺埗娓愬彉锛沗GlassTint` 涓嶅紩鍏ユ柊鐨?backdrop 灞?|

---

## 鍗併€侀獙鏀跺鐓ц〃

| 闇€姹?| 钀藉湴浣嶇疆 |
| --- | --- |
| 棣栨鎵撳紑濉啓鑱氬悎鏂伴椈 API Key锛堟湰鍦颁繚瀛樸€佷笉纭紪鐮侊級 | `onboarding_page.dart` + `hive_service.dart`锛圔ox `wentianxia_settings`锛? `news_repository.dart` 鐨?`apiKey` getter |
| 鍏磋叮绫诲埆鍕鹃€夛紙M3 Chip + 楂樻柉妯＄硦瀹瑰櫒锛?| `interest_selector.dart` |
| 闈炵┖鏍￠獙銆佷负绌轰笉寰楄繘鍏ヤ富鐣岄潰 | `TextFormField.validator` + `redirect` 鍙岄噸淇濋櫓 |
| `isFirstLaunch=false` / `apiKey` / `selectedCategories` 鎸佷箙鍖?| `HiveService.completeOnboarding()` |
| 鍚庣画鍚姩鐩存帴杩涗富鐣岄潰 | `app_router.dart` 鐨?`redirect` |
| 搴曢儴 Tab锛氭柊闂?/ 鏀惰棌 | `main_shell.dart`锛坄NavigationBar` + `StatefulShellRoute`锛?|
| `PageView` 鍨傜洿婊戝姩 | `news_feed_page.dart` |
| 鍥剧墖 35%~40% 灞忛珮 + `CachedNetworkImage`锛坧laceholder/errorWidget锛?| `news_card.dart`锛?.38锛? `news_network_image.dart` |
| 鏍囬 `headlineSmall` / 绠€浠?`bodyMedium` | `app_theme.dart` + `news_card.dart` |
| 銆岃鐪嬪叏鏂囥€嶆寜閽?| `news_card.dart`锛坄BlurButton`锛?|
| 棣栨潯缁х画涓婃粦瑙﹀彂鍒锋柊 | `_onScrollNotification`锛坄OverscrollNotification`锛?|
| 娴佺晠杩囨浮鍔ㄧ敾 | 鍗＄墖 `Hero` + 璇︽儏椤?`FadeTransition`/`SlideTransition` |
| 鍏ㄦ枃椤佃嚜鍔ㄦ粴鍔ㄣ€侀€熷害鍙皟 | `article_detail_page.dart`锛圱imer + ScrollController锛? 妗ｉ€熷害锛?|
| 椤靛唴鑷冲皯涓€寮犲浘鐗?| `_buildContent()` 椤堕儴 `NewsNetworkImage` + 娈佃惤闂存彃鍥?|
| 浣滆€?/ 鏉ユ簮淇℃伅 | 璇︽儏椤典綔鑰呰銆佹潵婧愯銆佸彂甯冩椂闂磋 |
| 銆岄槄璇诲師鏂囥€嶈烦娴忚鍣?| `url_launcher` + manifest `<queries>` |
| 鏀惰棌鍥炬爣鍒囨崲涓庢寔涔呭寲 | `isFavoriteProvider` + `Box<NewsArticle>` |
| 鏀惰棌椤电缉鐣ュ浘/鏍囬/鏀惰棌鏃堕棿 + 宸︽粦鍒犻櫎 | `favorites_page.dart`锛坄Dismissible`锛?|
| 楂樻柉妯＄硦瑙勮寖锛圔ackdropFilter + 鍙傛暟 10 + 灞€閮?Clip锛?| `blur_container.dart`锛?.0.1 璧疯壊甯?闂儊宸蹭慨锛岃鐗堟湰璁板綍锛?|
| 姣涚幓鐠冧笅鏂瑰浘鍍忕己澶?/ 婊戝姩闂儊 | **1.0.1 淇**锛氬幓鎺夋ā绯婃帶浠跺灞?`RepaintBoundary` + `GlassBackdrop` 鍏滃簳 + 涓€鏉?bar 涓€娆℃ā绯婏紙`BlurBar`/`GlassTint`锛夛紝鍥炲綊娴嬭瘯 `blur_regression_test.dart` |
| Material 3 涓婚锛坄ColorScheme.fromSeed` + NavigationBar/Card/Chip/FilledButton锛?| `app_theme.dart` |
| 閿欒鎻愮ず SnackBar + 閲嶈瘯 | `news_feed_page.dart` / `article_detail_page.dart` |
| 绌虹姸鎬併€岃繕娌℃湁鏀惰棌鐨勬柊闂汇€?| `favorites_page.dart` |
| 绠€浠嬫鎷紙浼樺厛 description锛屽惁鍒欐埅鍙?200 瀛楋級 | `NewsArticle.displaySummary` / `defaultSummary` |

---

## 鍗佷竴銆佸父瑙侀棶棰樹笌鍙栬垗

**1. `flutter pub get` 鎶ョ増鏈啿绐侊紵**
涓嶈鍐嶅崌绾?`freezed`銆傛湰椤圭洰鐢?`freezed 2.5.7` + `hive_generator ^2.0.1`锛?杩欐槸鍞竴鑳藉悓鏃剁敓鎴?Freezed 涓?Hive Adapter 鐨勭粍鍚堛€?
**2. 鍏ㄦ枃椤垫樉绀恒€屾憳瑕佹ā寮忋€嶏紵**
閮ㄥ垎绔欑偣涓?JS 鍔ㄦ€佹覆鏌撴垨鍋氫簡鍙嶆姄鍙栵紝`ArticleHtmlParser` 鎷夸笉鍒拌冻澶熸鏂囷紙鈮?60 瀛楋級鏃讹紝
浼氳嚜鍔ㄧ敤鎺ュ彛 `description` 鎷煎嚭鍙鍐呭锛屽苟鍦ㄩ〉闈笂鏍囨敞銆屾憳瑕佹ā寮忋€嶏紝
搴曢儴銆岄槄璇诲師鏂囥€嶄粛鍙烦杞煡鐪嬪畬鏁存姤閬撱€?
**3. 鍒锋柊鎻愮ず銆屼粖鏃ユ帴鍙ｈ皟鐢ㄦ鏁板凡鐢ㄥ畬銆嶏紵**
鑱氬悎鏁版嵁鍏嶈垂棰濆害涓?50 娆?澶╋紝搴旂敤鍗曟鍒锋柊鏈€澶氳姹?3 涓閬撱€?棰濆害鐢ㄥ敖鍚庡彲绛夋鏃ワ紝鎴栨敼鐢ㄥ閫夋暟鎹簮锛坄thenewsapi:<token>`锛夈€?
**4. 鏀惰棌閲岃兘绂荤嚎鐪嬪悧锛?*
鏍囬銆佹憳瑕併€佹潵婧愩€佹敹钘忔椂闂撮兘瀛樹簬 Hive锛岀绾垮彲璇伙紱姝ｆ枃闇€瑕佽仈缃戞姄鍙栥€?
**5. 涓轰粈涔?release 鐢?debug 绛惧悕锛?*
鏂逛究鐩存帴瀹夎楠岃瘉銆傛寮忓彂甯冭鍦?`android/app/build.gradle` 涓崲鎴愯嚜宸辩殑 keystore锛?骞舵妸 `signingConfig = signingConfigs.debug` 鏇挎崲涓?release 閰嶇疆銆?
**6. 姣涚幓鐠冧笅鏂瑰嚭鐜扮┖鐧藉甫 / 婊戝姩闂儊锛?.0.1 宸蹭慨澶嶏級锛?*
鏍瑰洜鏄?`BackdropFilter` 鐨勭鍏堥摼涓婂嚭鐜颁簡 `RepaintBoundary`锛屽鑷?backdrop 閲囨牱琚埅鏂€?淇鏂瑰紡涓庤鍒欒銆岀増鏈褰?路 1.0.1 淇璇︽儏銆嶅拰銆?.11.1 姣涚幓鐠冪殑灞傜粨鏋勮鍒欍€嶃€?`test/blur_regression_test.dart` 浼氭寔缁畧鎶よ繖涓ゆ潯绾︽潫鈥斺€斿鏋滀綘鐨勬敼鍔ㄨ娴嬭瘯澶辫触锛?璇存槑鍙堟妸 `RepaintBoundary` 鏀惧洖浜嗘ā绯婃帶浠剁殑涓婂眰銆?
**7. 妯＄硦鎺т欢寰堝浼氫笉浼氬崱锛?*
涓€灞忓彧鏋勫缓褰撳墠椤碉紙`PageView`锛夛紝姣忔潯 bar 鍙仛涓€娆℃ā绯婏紝鏉″唴鎸夐挳鐢?`GlassTint`
闈欐€佸～鍏呰€岄潪鍐嶅彔 backdrop锛屽洜姝?backdrop 灞傛暟閲忚鍘嬪埌鏈€灏戙€?`BackdropGroup` 鍏变韩閲囨牱浼樺寲鍙?Flutter 鐗堟湰闄愬埗锛屽崌绾у埌 3.35+ 鍚庢寜 6.11 鑺傛浛鎹竴琛屽嵆鍙紑鍚€?
---

## License

浠呬緵瀛︿範涓庝釜浜轰娇鐢ㄣ€傛柊闂诲唴瀹圭増鏉冨綊鍚勫師濯掍綋鎵€鏈夛紝鏈簲鐢ㄤ粎鍋氳仛鍚堝睍绀轰笌璺宠浆銆?
