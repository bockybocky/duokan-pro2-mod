# 多看電紙書 Pro II 改機紀錄：裝 Google Play、繁體中文、乾淨桌面

機型：多看電紙書 Pro II（Moaan rk3566_eink，Android 11，32 位元程式環境）。
目標：拿掉大陸版的預設桌面與書城，裝上 Google Play、改成繁體中文、換成適合電子紙的簡單桌面。

> ⚠️ **風險先講**：改機會動到開機分區，做錯可能讓機器開不了機。
> 動手前一定要把所有分區備份到電腦，並記下原版開機映像的雜湊值。
> 本文是個人紀錄，照做出事請自行負責。

## 需要的東西

- 電腦上的 `adb`（Google Platform Tools）
- 機器開啟「開發人員選項 → USB 偵錯」
- Magisk 31.1 安裝檔
- MindTheGapps 11.0 arm（32 位元）版本，用來做成 Magisk 擴充套件

## 步驟

### 1. 備份

1. 用 `adb pull` 備份整個內部儲存空間。
2. 備份每個分區（`boot_a`、`boot_b`、`vbmeta`、`waveform` 等），逐個比對雜湊值，確認跟機器上一致。
   `waveform` 是電子紙的顯示參數，每台不同，壞了很難救，一定要備份。

### 2. 用 Magisk 取得 root（最高管理權限）

1. 查出目前用的是哪一個開機槽：`adb shell getprop ro.boot.slot_suffix`。
2. 把那個槽的 boot 映像拉到手機，用 Magisk 程式修補。
3. 把修補過的映像寫回同一個槽。

**坑：adb 要 root 會被直接拒絕，連詢問視窗都不跳。**
`logcat` 只看得到 `su: request rejected (2000)`，Magisk 設定頁也找不到「超級使用者存取權」這個選項。

**解法：** 打開 Magisk →「超級使用者」頁 → 按左上角「＋」→ 選「殼層（com.android.shell）」。
加完之後，`adb shell su -c id` 就會回 `uid=0(root)`。

### 3. 裝 Google Play（一定要裝成系統元件）

**坑：把 Play 商店和 Google 服務框架當成一般程式裝，服務框架會一直當掉，因為它需要系統權限。**
移除它們的時候，系統還可能卡在重啟迴圈。用 `adb reboot` 冷開機就好了。**以後動到 Google 套件，一律冷開機。**

正確做法：

1. 把 MindTheGapps 11 arm 重新打包成 Magisk 擴充套件。可以拿掉用不到的元件，例如開機精靈、Google 助理、語音朗讀。
2. 先移除之前當一般程式裝的 Google 服務：`adb shell pm uninstall com.google.android.gms`。
3. 安裝擴充套件：
   ```
   adb push gapps_module.zip /data/local/tmp/gm.zip
   adb shell su -c 'magisk --install-module /data/local/tmp/gm.zip'
   adb reboot
   ```
4. 開機後檢查以下兩個位置：
   - `/product/priv-app` 裡要有 `Phonesky` 和 `PrebuiltGmsCore`
   - `/system_ext/priv-app` 裡要有 `GoogleServicesFramework`

### 4. 改成繁體中文

在設定裡改 `system_locales` 沒有用，要用 root 改系統屬性：

```
adb shell su -c 'setprop persist.sys.locale zh-TW'
adb reboot
```

### 5. 換成適合電子紙的桌面

1. 安裝 Olauncher（極簡文字桌面，F-Droid 上有），設成預設桌面。
2. 停用原本的多看桌面和微信讀書：`pm disable-user`。要復原就用 `pm enable`。

**坑：Olauncher 預設是深色主題，字是白的，電子紙底色也是白的，結果字幾乎看不見。**
解法：長按桌面 → Theme mode 改成 Light。
如果點了沒反應，可以用 root 在 `shared_prefs/app.olauncher.xml` 加一行 `<int name="APP_THEME" value="1" />`。

要手動改主畫面那幾格程式的話，每格除了填名稱、套件名、啟動畫面名稱，還要加 `APP_USER_N` 等於 `UserHandle{0}`，不然點下去不會開。
比較省事的做法：直接長按那一格，從清單裡選程式。

### 6. 閱讀程式

- **KOReader**：要裝 arm（32 位元）版，看 epub 和 pdf。
- **Readest**：要裝 armv7 版。
- **Mihon**：看漫畫，要裝 armeabi-v7a 版。第一次打開要選一個存檔資料夾。
- **HyRead**：可以用圖書館借書證免費借電子書。

**坑：Mihon 的資料夾選擇器，用 adb 模擬點擊，資料夾點了大多沒反應。**
解法：改用方向鍵移到資料夾上，再按確認鍵。不然就直接用手點。

**給小孩用：Mihon 兒童版來源（擋十八禁）**
放在 [`mihon-kids/`](mihon-kids/)。把動漫屋、嗶哩、拷貝、MyComic、MangaDex 改成兒童版，十八禁的書在列表裡藏起來，用網址硬開也是 0 章。做法、實測結果和限制見那份說明。

## 小工具

`tools/ui.sh`：用 `uiautomator` 把畫面上的文字和位置列出來，也能照文字去點。在電子紙上遠端操作時很好用。

```
bash tools/ui.sh dump        # 列出畫面上的文字和位置
bash tools/ui.sh tap "設定"   # 點畫面上寫著「設定」的地方
```

用之前，把檔案開頭的 `A=` 改成你電腦上 `adb` 的位置。

## 本資料庫不提供的東西

- 分區備份：每台機器專屬，不能共用。
- Google 套件與 Magisk 的安裝檔：請到各自的官方網站下載。
