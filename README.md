# WearLoop

记录衣橱、找回被遗忘的衣服、保存日常搭配，并把喜欢的穿搭分享出去。离线使用，无需注册。产品定义与数据模型见 [DESIGN.md](DESIGN.md)。

## 运行

要求 **Flutter 3.47.8 / Dart 3.13.7 或更新兼容版本**。当前项目使用的 Dart 语法及依赖无法用 Flutter 3.24 运行。

```bash
flutter pub get
flutter run              # 手机 / 模拟器
flutter run -d chrome    # Web
flutter analyze
flutter test
flutter build web --release
```

Windows 可在项目目录执行：

```powershell
.\tools\dev.ps1
# 或指定自己的 SDK 和端口
.\tools\dev.ps1 -FlutterSdk C:\develop\flutter -Port 5180
```

脚本优先使用指定 SDK，其次使用本次独立准备的 `%USERPROFILE%\.codex\runtimes\flutter-3.47.8`，最后使用 PATH 中的 Flutter；不会修改系统安装。

iOS 拍照与相册权限说明已配置。Android/iOS 真机上的相机、相册及系统分享需在相应设备验证。

## 界面与交互

- 暖白与鼠尾草绿的日常衣橱手记风格，包含随系统切换的深色主题。
- 手机底部四 Tab，桌面宽屏改为侧栏；内容限宽与网格按可用宽度调整。
- 今日：穿搭灵感、记录入口、可补记的最近七天日历、闲置单品、推荐组合与撤销记录。
- 衣橱：搜索名称/品牌/备注、带数量的分类筛选、五种排序、闲置提示。
- 搭配：搜索、场景/收藏筛选、排序、直接收藏、详情与分享。
- 洞察：四项指标、35 天日历、分类环图、常穿榜和单次成本榜；无数据时提供明确说明。
- 示例衣橱的 14 件衣物使用 AI 生成的透明底商品图；个人衣物优先展示上传照片，其余使用分类插画，无远程图片依赖。
- 详情、记录、编辑、历史、设置与分享使用一致的卡片和操作层级。

## 验证

自动化覆盖 320 / 400 / 768 / 1440 像素主页面、空衣橱与深色主题、搜索、日历记录入口，以及价格精度、搭配备注、记录日期迁移和搭配统计归属。运行 `flutter test` 查看结果。

原生端数据保存在本机 SQLite，图片存独立文件；Web 预览使用 `shared_preferences`。保留旧版数据迁移路径，界面与多语言改造不会重置现有衣橱。

## 手机 App 预览

Web 只是调试入口，产品目标仍是 Android / iOS App。运行 tools/dev.ps1 会默认使用手机预览；一般 Web 构建也可以在 URL 后加 ?preview=phone 进入手机框。原生 App 不带预览外框。

14 张透明素材的原图、使用方式与全部生成提示词见 [素材说明](assets/clothing/README.md)。


## 图标与 15 语言（1.2.0）

设置 → 语言，可跟随系统或选择中文、日语、韩语、英语、西班牙语、法语、德语、越南语、印地语、阿拉伯语、孟加拉语、葡萄牙语、俄语、乌尔都语、印尼语。每种语言有 422 条消息，并支持 RTL、系统日期控件及本地化数字输入。个人数据保留原文，CNY 金额不换算。

图标已改为衣架与叶片。[交付与验证记录](docs/I18N_RELEASE.md) 包含新 APK、84 项测试结果、平台资源和发布边界。

```bash
python tools/validate_i18n.py
flutter analyze --no-pub
flutter test --no-pub
```

原生数据使用本地 SQLite，图片存独立文件；Web 预览使用 shared_preferences。读取旧数据时保留已有迁移路径。
