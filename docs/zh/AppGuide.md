# 应用指南

## 目的

本文档解释 FitLog Local 每个 App 板块做什么、背后大致如何工作、以及应去哪里继续阅读。它是给用户和维护者看的地图，不替代 Product、Methodology、Algorithm、Database、AgentDesign 或 References。

## 全局规则

- FitLog Local 是 local-first：业务数据存储在 SQLite，除非用户主动导出。
- Home、Food Log 和 Workout Log 共享选中日期。
- App 没有内部 LLM/API/Agent loop。
- 外部 AI 可以帮助生成餐食估算，但数据进入 App 之后的存储、计算和展示都在本地完成。
- `diet_goal_phase` 控制 cutting/bulking 语义。
- `energy_ratio` 和 `gram_per_kg` 保持分离。
- 底部导航和固定 CTA 的 pill 只是视觉表面；根底部导航以 body overlay 绘制，而不是 `Scaffold.bottomNavigationBar` slot，pill 外区域不应再有 wrapper 填充或满宽 footer 色带。导航 pill 使用不透明的 `navBackground`，下半段背后放一块与 pill 等宽的 `background` 遮挡矩形，避免底部圆角外侧透出滚动内容。`FitLogBottomNavLayout` 是底部安全区间距、导航 footprint、Home 首屏盒子、固定 CTA 位置、滚动底部留白和说明弹窗底部避让的唯一来源。
- 说明类 modal sheet 通过 route 遮罩压暗并禁用底部导航，但可见内容停在导航 footprint 上方，导航 pill 不应覆盖 sheet 正文。它们需要保留顶部焦点留白，较长文案在面板内部滚动。
- App 内系统通知统一走 `FitLogNotifications`：成功/中性提示是更紧凑的轻量顶部 overlay，不显示手动关闭控件；错误/action 提示浮在键盘或底部导航 footprint 上方。业务页面保留原保存、删除、导出顺序，并把原始消息文本交给统一通知层，包括错误详情。
- Android 训练进行中通知是面向活动训练草稿的平台通知。它只同步草稿状态，不执行云端或后台计算；用户点击通知主体时会返回训练编辑页。
- 新建 Add Workout 草稿只有在用户离开 App 前仍停留在草稿编辑页、轻量 active 标记存在、且 SQLite 草稿 30 分钟内更新过时，才会在进程重建后自动打开一次。App 不为此使用后台 Timer、Alarm、Worker、前台服务、WakeLock 或保活机制。
- Android APK 安装后的启动器显示名是 `FitLog local`，来源是 `android/app/src/main/AndroidManifest.xml`；包名仍保持 `com.fitlog.local.fitlog_local`，因此覆盖更新会继续使用同一个本地数据沙盒。启动器图标由 `assets/icons/app/fitlog.png` 生成到 `android/app/src/main/res/mipmap-*/ic_launcher.png` 各密度资源。

延伸阅读：

- 产品范围：[Product](Product.md)
- 方法原因：[Methodology](Methodology.md)
- AI 边界：[AgentDesign](AgentDesign.md)

## 首页

Home 是选中日期的每日入口页。

用户可见内容：

- 根据本地时间变化的问候语；当昵称过长时，昵称会单独从第二行开始显示
- 已保存昵称；若为空则使用本地 fallback
- 选中日期
- `energy_ratio` 下的主 kcal 概览
- `gram_per_kg` 下的专属宏量进度 hero
- 在 `energy_ratio` 下显示蛋白质、碳水、脂肪的三张等尺寸宏量小卡片，并使用独立 PNG 资产渲染图标
- 当前 `diet_goal_phase`、`diet_calculation_mode` 和 `diet_plan_strategy`
- 简洁的当日饮食/训练摘要，并可跳转到副页

工作方式：

- `DailySummaryService` 读取 Profile、Food、Workout、校准、自检和策略数据。
- 食物总量来自已保存的 `food_records`。
- 训练总量来自已保存的 `workout_sessions.estimated_calories`。
- 训练摘要旁的数量按选中日期的 `workout_sessions` 条目数统计，每个已保存动作计一个，不按 `plan_id` 分组后的训练记录数统计，因此 Home 使用“个动作”作为单位。
- `energy_ratio` 以 kcal 目标/摄入/剩余为主，因此 Home 顶部保留热量圆环和 kcal 摘要指标。
- `gram_per_kg` 以宏量克数为主，kcal 只是辅助信息，因此 Home 顶部改为专属宏量 dashboard：左侧裁切大圆环负责进度，右侧提示当前完成度最低的宏量和剩余克数。
- 在 `gram_per_kg` 下，饮食摄入和训练消耗 kcal 会收进 macro dashboard 内，作为可点击的紧凑摘要，而不是继续占用独立的今日记录卡片。
- 在 `gram_per_kg` 下，裁切大圆环会比标题更强势，首屏看起来更像一个完整的仪表盘，而不是多个小段落拼在一起。
- 在 `gram_per_kg` 下，底部纵向明细列表会继续保留，但去掉明显分割线，用更连续的留白把圆环、焦点状态和三项宏量连成一个整体。
- 策略字段展示 `none`、`carb_cycling` 或 `carb_tapering` 应用后的最终目标上下文。
- 当碳循环或碳水渐降启用时，Home 的策略卡片可以点开，并展示会避让底部导航、面向非熟悉用户的结构化方法说明。
- 英文界面下，Home 已启用策略卡片会把 `- ...` 状态后缀固定放到第二行，避免碳循环或碳水渐降状态在窄屏上挤成过长一行。
- 在 `gram_per_kg` 下，策略卡片位于首屏宏量区域之后，用户需要下滑后才会看到解释入口，首页打开时只聚焦宏量执行信息。
- 在 `energy_ratio` 下，首屏会被当作一个只容纳热量卡片和宏量卡片的专用大盒子：盒子里只放这两张卡片，二者之间的距离保持受控，宏量卡片下方只保留较短的保护间距，避免策略卡片前出现大段空白。
- 在 `gram_per_kg` 下，策略卡片之所以位于首屏之后，主要来自专属宏量 dashboard 自身的大区域容器，而不是使用 `energy_ratio` 那种先测量内容再计算留白的方式。
- BMR、TDEE、校准细节和长表单设置不堆在 Home。

延伸阅读：

- 每日看板行为：[Product](Product.md#每日看板行为)
- 计算原因：[Methodology](Methodology.md)
- 公式：[Algorithm](Algorithm.md)
- 运行时聚合字段：[Database](Database.md#运行时聚合)

## 饮食记录

Food Log 是选中日期的饮食记录列表。

用户可执行操作：

- 查看选中日期的已保存餐食
- 打开并编辑一条记录
- 把记录复制到其他日期
- 确认后删除记录
- 进入 Add Food
- 滑到当天记录列表底部后查看估算说明

工作方式：

- 一餐存为一条 `FoodRecord`。
- 可选 item 行存为 `FoodItem`。
- `source` 记录该餐来自手动录入还是外部 AI 粘贴。
- 复制会创建新的本地记录和新的 id/timestamp。
- 删除一条饮食记录会级联删除其 item 行。
- `添加食物` CTA 以底部 overlay pill 绘制，而不是一条满宽 footer 行；`FitLogBottomNavLayout` 让它的底边锚定在导航 pill 上方，并给饮食列表保留足够的底部留白，保证记录能滚到按钮上方。

延伸阅读：

- 饮食流程：[Product](Product.md#饮食流程)
- 数据表：[Database](Database.md#food_records)、[Database](Database.md#food_items)
- AI 相邻边界：[AgentDesign](AgentDesign.md)

## 添加饮食

Add Food 是饮食录入入口页。

入口选项：

- `AI 辅助录入`：高亮入口，用于复制 Prompt、粘贴外部 AI JSON、全屏 JSON 编辑和本地解析。
- `Manual Entry`：手动输入食物数据。

工作方式：

- Add Food 的高亮卡片会打开一个完整的 AI 辅助录入工作台，避免用户需要从两个分离入口自行理解 Prompt 复制和 JSON 粘贴之间的关系。
- 该卡片副标题刻意写成两行：复制 Prompt 给外部 AI，粘贴返回的完整 JSON。
- 工作台内的 Prompt copy 是静态文本复制，不是 AI 调用。它通过长期对话规则让新的食物图片通常开始一份新餐食，并让增加/删除/替换/重新计算等追问更新最近一餐，无需重复复制 Prompt。
- 外部模型每次回复都必须是单个完整严格 JSON 对象；顶层重量、热量、蛋白质、碳水和脂肪由最终 item 数值重新加总。现有 schema 和最后一个 `estimation_notes` 字段保持不变，不包含也不要求 `comment` 字段。
- 设置卡采用 Agent 版的嵌套视觉样式：第一部分把使用方式压缩成带圆圈标记的三个一行动作，第二部分保留面向 ChatGPT 用户的推荐 GPT 信息。复制成功使用简短、不绑定具体模型的顶部提示和按钮内已复制状态。
- 粘贴页使用固定 `CustomMultiChildLayout`：设置卡保留原始占位，只根据真实键盘 inset 渐隐并持续挂载；JSON 编辑卡保持原始尺寸，只通过直接 `Transform.translate` 公式移动；解析按钮停留在原始底部位置并可被系统键盘自然覆盖。AppBar 和页面背景不随键盘改变，也不在系统键盘动画之上叠加额外 Flutter tween、渐变、模糊、聚焦遮罩或布局尺寸动画。Widget 测试会验证透明度、位移连续性、键盘打开时禁用交互，以及 inset 归零后完整恢复。
- 粘贴的 JSON 由 `NutritionCalculator` 在本地解析。
- 预览页允许用户修正解析结果后再保存。
- Food Detail、AI 预览页和 Manual Entry 都使用面向用户的字段标签，不再直接显示 snake_case；数字单位放在输入框后缀，底层 JSON key 和存储字段保持不变。
- Manual Entry 会复用 Food Detail 主区块的紧凑网格：餐名全宽，重量和热量同排，蛋白质/碳水/脂肪同排，备注全宽。
- 手动录入会直接写入本地记录。

延伸阅读：

- 产品行为：[Product](Product.md#饮食流程)
- AI 边界：[AgentDesign](AgentDesign.md)
- 解析与汇总公式：[Algorithm](Algorithm.md#food-intake-summary)

## 训练记录

Workout Log 是选中日期的训练记录列表。

页面标题下方直接进入共享日期条，不再额外放置日历前说明文字。

用户可执行操作：

- 查看选中日期的训练记录
- 打开一条已保存记录
- 删除已保存记录
- 进入 Add/Edit Workout Record
- 当 30 分钟冷启动条件满足时，进程重建后自动回到最近仍 active 的新建 Add Workout 草稿
- 从 `添加训练` 上方的双行浮动草稿条恢复一条未保存训练
- 从 Android 训练通知主体恢复当前训练草稿
- 在确认后从浮动草稿条直接舍弃这条草稿

工作方式：

- 一条面向用户的 `Workout Record` 可以包含多个动作。
- 在存储层，一个多动作记录是多条共享 `plan_id` 的 `workout_sessions`。
- 同一记录内每条 session 也保存相同的 `record_name`。
- 训练模块还可以单独保留一条未保存草稿；它不属于正式训练列表，也不算已保存训练记录，并且会以标题/副标题摘要条的形式显示，副标题使用短部位名，最多直接显示三个部位，超过后改为 `+n`，而不是单行警示文案。
- 冷启动自动恢复只是一次自动导航判断。SQLite active draft 仍是权威数据；过期草稿或不再带 active 标记的草稿不会自动打开，但仍可从 Workout Log 草稿条手动恢复。
- Android 训练通知使用同一条活动草稿。点击通知主体会打开草稿编辑页；系统展开箭头仍是 Android 控制的展开/折叠入口。
- 记录级摘要由已保存的 session 和 set 推导而来。
- 动作缩略图现在会优先使用已匹配动作的透明 PNG 资产；未匹配到具体动作图标时，仍回退到按身体部位区分的共享 SVG 图标。
- `添加训练` CTA 和可选草稿条以底部 overlay 绘制，而不是一条满宽 footer 行；`FitLogBottomNavLayout` 让它们的底边锚定在导航 pill 上方，并给训练列表保留足够的底部留白，保证记录能滚到控件上方。

延伸阅读：

- 训练流程：[Product](Product.md#训练流程)
- 训练表：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## 添加/编辑训练记录

Add/Edit Workout Record 是创建或修改训练记录的页面。

用户可执行操作：

- 给训练记录命名
- 从当前胸部、背部、腿部、臀部、肩部、手臂、核心、全身、有氧和可复用自定义动作库中选择一个或多个动作
- 为当前记录添加一个临时自定义力量或有氧动作
- 在 `自定义动作` 分组页内左滑已保存的可复用自定义动作并删除
- 保持动作的用户选择顺序
- 输入每个动作的时长
- 按可维持时长选择有氧本次强度
- 输入力量组的重量、次数或单组时长，以及完成状态
- 添加备注
- 如果用户离开 App 前仍停留在新建草稿编辑页，且 30 分钟内发生进程重建，可以自动回到编辑页
- 暂时离开编辑页，稍后通过训练页浮动草稿条继续回来编辑
- 当活动力量草稿存在时，也可以稍后通过 Android 训练通知回到编辑页
- 通过编辑页内的红色危险操作舍弃新建草稿，或放弃对已保存记录的未保存修改
- 保存已完成的力量组

工作方式：

- 动作选择支持按部位筛选、搜索和多选顺序。
- 可复用自定义动作会出现在独立的 `自定义动作` 分组中，而不是混在内置部位分组里。
- 临时自定义动作可以在保存训练记录时写入本地可复用自定义动作库。
- 当用户位于 `自定义动作` 分组时，已保存的可复用自定义动作可以通过列表内左滑并确认的方式从未来选择中隐藏。
- 临时自定义动作页不再是单纯的纵向下拉表单；它沿用 `添加训练` 页级标题的字号，先显示紧凑的滑块式力量/有氧切换，把动作名放进独立身份卡，再把力量 metadata 放进可点按的 bento tile，使用短 tile 标签，必要时让重量口径独占一行，并且只在非常窄的屏幕上才降级为单列，section title 也对齐训练卡片标题字号，整体字号收回到真实手机界面的比例，并使用底部固定添加按钮。
- 有氧动作使用时长和本次强度，不需要组清单。
- 时长说明显示在有氧时长输入框上方，强度解释显示在本次强度选择器上方，避免小屏下拉框文案溢出。
- 间歇/极高强度有氧会要求填写实际运动时长，避免把休息时间高估为极高强度运动。
- 力量动作使用组行，并保存当次使用的输入口径。
- 内置和自定义力量动作可以使用总重量、每侧重量、自重加重、辅助重量、总次数、每侧次数或单组时长。
- 辅助类自重动作在重量字段里记录的是辅助重量；估算消耗时按 `体重 - 辅助重量` 计算实际负重。
- 编辑过程中会自动保存草稿；只有用户显式保存且校验通过后，才会写入正式记录。
- 当 App 在用户仍停留于新建 Add Workout 草稿编辑页时进入 `inactive`、`paused` 或 `hidden`，编辑页会立即保存草稿，并在轻量本地偏好中标记编辑器仍 active。
- Root 首次 post-frame 启动检查时，如果 active 标记存在、新建草稿的 `updatedAt` 距当前不超过 30 分钟，就只打开一次 Add Workout，并恢复原日期、动作、组行、重量/次数或时长输入、完成状态、记录名和备注。
- 返回或手势退出时保留草稿，不再弹出保存/舍弃模态框，但会清除自动恢复标记，因此之后重启不会自动打开编辑页。
- 舍弃草稿、保存正式记录、草稿被清空或删除时也会清除自动恢复标记。SharedPreferences 标记读写失败不影响 SQLite 草稿持久化；编辑已有历史训练产生的草稿不参与新建训练的冷启动自动恢复。
- 活动中的 Android 力量草稿通知标题只显示当前动作名，正文显示下一组，例如 `第 2 组，共 9 组 - 50 kg x 8 次`。
- 通知焦点跟随最近一次勾选完成的组。如果该动作还有未完成组，通知继续显示该动作；如果该动作已经全部完成，通知回到训练记录顺序中第一项仍有未完成组的动作。
- 通知 large icon 使用当前动作图片。状态栏小图标使用由 `assets/icons/app/fitlog_notification_small.svg` 这个透明 FitLog SVG 源文件转换出的 Android drawable，但 Android 仍可能把这个位置渲染成系统控制的单色图标。
- 只有已完成的力量组会被保存；未勾选组会被丢弃。
- 编辑已保存记录时，会事务性替换整个 `plan_id` 分组。

延伸阅读：

- 产品流程：[Product](Product.md#训练流程)
- 运动消耗原因：[Methodology](Methodology.md#为什么运动消耗使用净消耗)、[Methodology](Methodology.md#为什么力量训练不按分钟线性算)
- 公式：[Algorithm](Algorithm.md#workout-calories)
- 存储模型：[Database](Database.md#workout_sessions)

## 训练记录详情

Workout Record Detail 用来解释一条已保存训练记录。

用户可见内容：

- 记录名
- 日期和开始时间
- 总时长
- 总训练量
- 总组数
- 估算消耗
- 记录中的动作
- 已保存的力量组细节
- 保存时的力量输入标签，例如每侧重量、每侧次数、辅助重量或单组时长
- 保存时的有氧本次强度；如果存在，也显示实际运动时间

工作方式：

- 摘要指标由已保存的 session 和 set 推导。
- 总训练量基于力量组里保存的标准化计算值。
- 组数是已保存力量组的数量。
- 在当前记录流中，已保存力量详情的完成状态是只读的。
- 详情页保留用户当时填写的内容和保存时使用的计算口径，所以之后修改可复用自定义动作不会重新解释旧记录。

延伸阅读：

- 产品行为：[Product](Product.md#训练流程)
- 数据模型：[Database](Database.md#workout_sessions)、[Database](Database.md#workout_sets)

## 我的资料

Profile 是一个“摘要优先”的控制台，用于配置本地身份、身体资料、饮食行为、主题、语言、导出和本地数据操作。

用户可设置内容：

- 仅用于本地 UI 展示的昵称，显示在 `用户设置` 页头下方的一行紧凑身份行中，右侧笔形入口触发页面顶部就地编辑
- 顶部当前计划摘要与宏量目标 strip，其中蛋白质、碳水和脂肪图标徽章底色与 Home 使用的对应营养素颜色一致
- 身体资料摘要网格
- 年龄、身高、体重、性别、体脂率和腰围，并放进默认展示态的身体资料网格
- 通过身体资料卡的日历入口打开日期选择器，再在卡片内补记或编辑过往日期的体重、体脂率和腰围
- 本地主题偏好：绿色、蓝色或黑橙
- 语言
- `diet_goal_phase`
- `diet_calculation_mode`
- 两种饮食模式共享的训练频率设置和自检设置
- `energy_ratio` 的每日能量目标和宏量百分比
- `gram_per_kg` 的表格上下文和宏量优先预览
- `diet_plan_strategy`
- carb cycling pattern 和 multiplier
- carb taper review 周期、目标减重速度、步长和当前 offset

工作方式：

- Profile 保存到单例 `user_profile`。
- `nickname` 是本地 UI 数据，不是账号名。
- 主题是保存在 SQLite 之外的本地 UI 偏好；它只重新映射 App 颜色 token，不改变饮食、训练、资料或计算行为。
- 蓝色主题使用完整的青蓝衍生 palette，而不是单点替换颜色：`#55DCE2` 留给明亮柔和的实色按钮和强填充，纯白用于页面、普通卡片、输入框、Profile 内层 tile 和信息型区域，底部导航 pill 仍是独立表面且 pill 外区域露出页面背景，浅青色用于选中 pill 和小型强调徽章，深青蓝/靛蓝用于可读文字、图标和描边。
- 黑色主题让橙色保持强调用途，同时拆分深色背景、卡片、选中表面、输入、描边和文字角色，保证层级更清楚。
- 保存 Profile 也会 upsert 当天体重日志；保存当前身体资料时，还会把当天体重、体脂率和腰围写入本地身体指标历史。
- 首屏故意不再是密集编辑表单；当前计划、身体资料、计划矩阵和训练频率设置会先出现，后面再接参考、导出等较低频区域。
- 昵称、身体资料和 `energy_ratio` 这类输入型卡片默认是展示态，发生编辑后才在本卡片内显示保存动作；未改动的内联编辑态点别处可收起，chips 和 switch 这类离散项直接保存。
- 身体资料会进入统一的当前 Profile 编辑态：点开年龄、身高、体重、性别、体脂率或腰围任意一个 tile 后，整个网格都会进入可切换编辑状态，并通过一次保存持久化当前 Profile 快照。
- 身体资料卡的日历入口与当前 Profile 编辑分离：它先打开默认选中今天的应用日期选择器，选择过去日期后进入卡片内编辑态，并只编辑该日期的体重、体脂率和腰围身体指标记录；选择今天会退出历史编辑并回到当前身体资料卡；编辑过去日期时其它 Profile 区域和底部导航会柔和淡化并锁定。
- 已有的过往身体指标记录会在日期条旁显示紧凑删除入口；删除必须确认，并会移除该日期的身体指标记录，如果该记录包含体重，也会移除同步的体重日志。确认弹窗保持普通主题 surface，取消是普通文字动作，删除使用无填充的红色图标文字按钮，明确危险语义但不和绿色保存/确认动作冲突。
- Profile 内联数字编辑器使用透明的卡片内输入框并保持 tile 尺寸稳定；键盘弹出时，当前焦点输入可滚动到键盘上方，底部导航保持固定。
- 身体趋势卡是只读展示层，可切换体重、体脂率和腰围，不承载完整历史记录列表；图表默认保持干净，只有点按记录点时显示日期和值。点位从当前范围内第一条可见记录开始绘制，并按所选 7/14/21/28 天范围缩放横向间距；水平参考线来自可读的指标刻度，小范围优先使用 1 kg/cm/%，大范围自动提升到 2/5/10 等更稀疏的间隔，但不显示坐标轴数字。如果今天还没有按日期保存的身体指标记录，图表会用当前已保存身体资料作为今天的展示点，但不会因此写入历史记录。
- 英文版 Profile 继续使用紧凑文案，包括无饮食策略时显示 `N/A`，以及更短的训练频率自检当前值/建议值与操作按钮文案。
- 当前计划 hero 带有一个信息入口，点击后会打开与首页策略说明相同尺寸和出场方式、并避让底部导航的 guide sheet；内容会随当前饮食模式切换，在 `gram_per_kg` 与 `energy_ratio` 之间切换不同表格和说明。
- `energy_ratio` 模式下，热量比例设置卡会直接出现在计划矩阵下面、共享训练频率/自检卡上面，保证模式切换与对应输入在同一视线区域。
- `g/kg` 设置卡不再重复展示自检摘要行，也不再把长段解释文字塞在卡片底部；完整训练频率自检卡保留在其下方的独立区域，而方法说明迁入信息弹窗。
- 未成年人保护会阻止成人式 cutting deficit 行为和 cutting carb 策略。
- 训练频率自检会在两种饮食模式下根据最近有效训练日推荐共享训练频率设置。
- Carb taper review 可以给出本地建议，但必须由用户确认。

延伸阅读：

- 产品行为：[Product](Product.md#饮食设置交互)
- 面向用户的方法解释：[Methodology](Methodology.md)
- 算法细节：[Algorithm](Algorithm.md)
- Profile 表：[Database](Database.md#user_profile)

## 导出

Export 为用户记录生成本地文件。

导出内容包括：

- food records
- food items
- 训练记录父表，每条已保存训练记录分组一行
- 训练动作/组明细表，通过训练记录 ID 关联父表
- daily summary
- user profile
- body metric history
- diet adjustment review history
- 策略、校准、自检、当前身体资料和本地 nickname 等相关字段

工作方式：

- XLSX 和 CSV ZIP 写入 app documents directory。
- 导出的表名、XLSX sheet 名、CSV 文件名、表头和可识别枚举值会跟随当前 App 语言。
- 当导出内容至少有一条记录时，导出文件名使用 `fitlog_local_<first_record_date>_to_<export_date>`，日期格式为 `yyyy_MM_dd`。
- 文件生成后，Profile 会打开系统分享面板，让用户选择任意已安装且支持该文件的发送目标。
- Daily summary export 在导出时由 repositories 和 `DailySummaryService` 生成。
- Export 不会上传任何数据。

延伸阅读：

- 导出覆盖：[Database](Database.md#导出覆盖)
- 产品边界：[Product](Product.md#已实现边界)

## 语言

Language 负责切换中英文 UI。

用户可执行操作：

- 切换 English 和 中文

工作方式：

- 语言偏好保存到 `SharedPreferences`。
- Prompt 文案和普通 UI 文案都随语言切换。

## 隐私与本地优先边界

- 业务数据保存在本地 SQLite。
- 导出生成本地文件，不做云上传。
- Prompt 复制和 JSON 粘贴是用户驱动的外部 AI 辅助流程，不是 App 内 AI。

延伸阅读：

- 数据库存储：[Database](Database.md)
- AI 边界：[AgentDesign](AgentDesign.md)
- 证据和安全边界：[References](References.md)

