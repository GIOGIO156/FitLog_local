import '../constants/prompt_templates.dart';
import 'app_language.dart';

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  bool get isChinese => language == AppLanguage.chinese;

  String _t(String en, String zh) => isChinese ? zh : en;

  String get appName => _t('FitLog Local', 'FitLog Local');

  String get homeDashboardTitle => _t('Home / Daily Dashboard', '首页 / 每日看板');
  String get foodLogTitle => _t('Food Log', '饮食记录');
  String get workoutLogTitle => _t('Workout Log', '训练记录');
  String get profileSettingsTitle => _t('Profile & Settings', '资料与设置');

  String get navHome => _t('Home', '首页');
  String get navFood => _t('Food', '饮食');
  String get navWorkout => _t('Workout', '训练');
  String get navProfile => _t('Profile', '我的');

  String get quickActions => _t('Quick Actions', '快捷操作');
  String get addFood => _t('Add Food', '添加食物');
  String get addWorkout => _t('Add Workout', '添加训练');
  String get saveWorkoutPlan => _t('Save Workout Plan', '保存训练计划');

  String get copyAiFoodPrompt => _t('Copy AI Food Prompt', '复制 AI 食物提示词');
  String get promptCopied => _t(
    'AI food prompt copied. Paste it into ChatGPT or Gemini after uploading your food photo.',
    'AI 食物提示词已复制。上传食物照片后，请粘贴到 ChatGPT 或 Gemini。',
  );

  String get estimateNotice => _t(
    'All values are estimates for personal logging. Energy ratio uses the deficit target plus logged net exercise; g/kg uses the bodyweight table independently.',
    '所有数值仅用于个人记录估算：热量赤字算法会加入已记录净运动消耗；g/kg 按体重查表独立计算。',
  );

  String get noFoodRecords => _t(
    'No food records yet. Tap Add Food to start logging.',
    '还没有食物记录，点击“添加食物”开始记录。',
  );

  String failedToLoadFood(Object error) =>
      _t('Failed to load food records: $error', '加载食物记录失败：$error');

  String get deleteRecord => _t('Delete Record', '删除记录');
  String get delete => _t('Delete', '删除');
  String get copy => _t('Copy', '复制');
  String get cancel => _t('Cancel', '取消');
  String get date => _t('Date', '日期');
  String get change => _t('Change', '修改');

  String deleteFoodConfirm(String mealName, String date) =>
      _t('Delete "$mealName" on $date?', '确认删除 $date 的“$mealName”？');

  String get foodDeleted => _t('Food record deleted.', '食物记录已删除。');

  String foodCopied(String mealName, String date) =>
      _t('"$mealName" copied to $date.', '已将 "$mealName" 复制到 $date。');

  String failedToCopyFood(Object error) =>
      _t('Failed to copy food record: $error', '复制食物记录失败: $error');

  String sourceLabel(String source) {
    switch (source) {
      case 'ai_paste':
        return _t('AI Paste', 'AI 粘贴');
      case 'manual':
        return _t('Manual', '手动录入');
      default:
        return source;
    }
  }

  String get recommendedFlow => _t('Recommended Flow', '推荐流程');
  String get step1 => _t('1. Open ChatGPT or Gemini', '1. 打开 ChatGPT 或 Gemini');
  String get step2 => _t('2. Upload or take a food photo', '2. 上传或拍摄食物照片');
  String get step3 => _t('3. Paste the copied prompt', '3. 粘贴已复制的提示词');
  String get step4 => _t('4. Copy the JSON result', '4. 复制 JSON 结果');
  String get step5 =>
      _t('5. Return here and tap Paste AI Result', '5. 返回这里并点击“粘贴 AI 结果”');

  String get recommendedGpt => _t('Recommended GPT', '推荐 GPT');

  String get recommendedGptHint {
    if (isChinese) {
      return '中文：打开 ${PromptTemplates.chineseGptName}\nEnglish: Open ${PromptTemplates.englishGptName}';
    }
    return 'Chinese: Open ${PromptTemplates.chineseGptName}\nEnglish: Open ${PromptTemplates.englishGptName}';
  }

  String get pasteAiResult => _t('Paste AI Result', '粘贴 AI 结果');
  String get pasteAiSubtitle =>
      _t('Paste ChatGPT/Gemini JSON and parse', '粘贴 ChatGPT/Gemini JSON 并解析');
  String get manualEntry => _t('Manual Entry', '手动录入');
  String get manualEntrySubtitle =>
      _t('Manually input a food record', '手动填写一条食物记录');
  String get photoAiAnalysis => _t('Photo AI Analysis', '图片 AI 分析');
  String get comingSoon => _t('Coming soon', '即将上线');

  String get pasteInstruction => _t(
    'Paste the JSON output from ChatGPT or Gemini:',
    '粘贴来自 ChatGPT 或 Gemini 的 JSON 输出：',
  );

  String get parse => _t('Parse', '解析');
  String get parsing => _t('Parsing...', '解析中...');

  String get pleasePasteJson => _t('Please paste JSON first.', '请先粘贴 JSON 内容。');

  String parseError(String message) =>
      _t('Unable to parse JSON: $message', 'JSON 解析失败：$message');

  String get parseErrorGeneric =>
      _t('Unable to parse JSON. Please check the format.', '无法解析 JSON，请检查格式。');

  String get bodyProfileGoal => _t('Body Profile & Goal', '身体资料与目标');
  String get ageLabel => _t('Age', '年龄');
  String get heightCmLabel => _t('Height (cm)', '身高 (cm)');
  String get weightKgLabel => _t('Weight (kg)', '体重 (kg)');
  String get sexForFormulaLabel => _t('Sex for Formula', 'BMR 性别参数');
  String get activityLevelLabel => _t('Activity Level', '活动水平');
  String get goalPhaseLabel => _t('Goal phase', '目标阶段');
  String get cuttingLabel => _t('Cutting', '减脂期');
  String get bulkingLabel => _t('Bulking', '增肌期');
  String get dailyGoalTypeLabel => _t('Daily Goal Type', '每日目标类型');
  String dailyGoalKcalLabelForPhase(String phase) =>
      phase == 'bulking'
          ? _t('Daily Calorie Surplus (kcal)', '每日热量盈余 (kcal)')
          : _t('Daily Calorie Deficit (kcal)', '每日热量赤字 (kcal)');
  String get dailyGoalKcalLabel => dailyGoalKcalLabelForPhase('cutting');
  String get dietCalculationModeLabel => _t('Diet calculation method', '饮食计算方法');
  String get energyRatioModeLabel =>
      _t('Energy ratio method', '热量比例算法');
  String get gramPerKgModeLabel =>
      _t('g/kg bodyweight method', 'g/kg 体重算法');
  String get trainingFrequencyPerWeekLabel =>
      _t('Training Frequency Tier / Week', '每周训练频率档位');
  String trainingFrequencyOptionLabel(int value) =>
      _t('$value sessions/week tier', '每周 $value 次档位');
  String get macroSelfCheckPeriodLabel => _t('Self-check Period', '自检周期');
  String macroSelfCheckPeriodOptionLabel(int value) =>
      _t('$value days', '$value 天');
  String get macroSelfCheckEnabledLabel =>
      _t('Enable training history self-check suggestions', '启用历史训练记录自检建议');
  String get macroSelfCheckTitle =>
      _t('Training Frequency Self-check', '训练频率自检');
  String get applySuggestion => _t('Apply Suggestion', '应用建议');
  String get keepCurrentSetting => _t('Keep Current Setting', '保持当前设置');
  String get macroSelfCheckNoData =>
      _t('No valid training days in selected period yet.', '所选周期内暂无有效训练日。');
  String get macroSelfCheckConsistent => _t(
    'Current setting is consistent with recent training history.',
    '当前设置与历史训练记录基本一致。',
  );
  String get macroSelfCheckReminderCooldownHint => _t(
    'A recommendation exists but reminder cooldown is active. You can adjust it manually below.',
    '当前存在推荐档位，但提醒冷却中。你可以在下方手动调整。',
  );
  String macroSelfCheckCurrentFrequencyText(int value) =>
      _t('Current setting: $value sessions/week', '当前设置：每周训练 $value 次');
  String macroSelfCheckActiveDaysText(int periodDays, int activeDays) => _t(
    'Past $periodDays days: trained on $activeDays days',
    '过去 $periodDays 天：实际训练 $activeDays 天',
  );
  String macroSelfCheckAverageFrequencyText(double weeklyFrequency) => _t(
    'Logged frequency: about ${weeklyFrequency.toStringAsFixed(1)} sessions/week',
    '记录折算频率：约每周 ${weeklyFrequency.toStringAsFixed(1)} 次',
  );
  String macroSelfCheckRecommendedText(int value) => _t(
    'Suggested g/kg tier: $value sessions/week',
    '建议将 g/kg 档位调整为：每周训练 $value 次',
  );
  String get macroSelfCheckBelowRangeNotice => _t(
    'Recent logged frequency is below the g/kg table range. Use the 2 sessions/week tier or switch back to Energy Ratio Deficit mode.',
    '历史记录频率低于 g/kg 表格范围，建议使用每周 2 次档位，或切换回热量赤字比例算法。',
  );
  String get macroRatioSettingsLabel =>
      _t('Daily Macro Ratio (%)', '每日三大营养比例 (%)');
  String get bulkingMacroRatioSuggestion => _t(
    'Default bulking suggestion: protein 25%, carbs 50%, fat 25%.',
    '增肌期默认比例建议：protein 25%, carbs 50%, fat 25%。',
  );
  String get proteinRatioPercentLabel => _t('Protein Ratio (%)', '蛋白质比例 (%)');
  String get carbsRatioPercentLabel => _t('Carbs Ratio (%)', '碳水比例 (%)');
  String get fatRatioPercentLabel => _t('Fat Ratio (%)', '脂肪比例 (%)');
  String get macroRatioHint =>
      _t('Protein + Carbs + Fat should equal 100%.', '蛋白质 + 碳水 + 脂肪 应等于 100%。');
  String get macroRatioTotalInvalid =>
      _t('Macro ratio total must be 100.', '三大营养比例总和必须为 100。');
  String get enterValidMacroRatio =>
      _t('Enter a valid ratio between 0 and 100.', '请输入 0 到 100 的有效比例。');
  String get dateLabel => _t('Date', '日期');
  String get notesLabel => _t('Notes', '备注');
  String get durationMinutesLabel => _t('Duration (minutes)', '时长 (分钟)');
  String get bodyWeightKgLabel => _t('Body Weight (kg)', '体重 (kg)');
  String get intensityLabelText => _t('Intensity', '强度');
  String get estimatedCaloriesLabel => _t('Estimated Calories', '估算消耗');
  String get estimatedTotalCaloriesLabel =>
      _t('Estimated Total Calories', '计划总估算消耗');
  String get calculatedReference => _t('Calculated Reference', '计算参考');
  String get exportData => _t('Export & Data', '导出与数据');
  String get exportXlsx => _t('Export XLSX', '导出 XLSX');
  String get exportCsv => _t('Export CSV', '导出 CSV');
  String get clearAllData => _t('Clear All Local Data', '清空本地数据');

  String get languageSettings => _t('Language', '语言设置');
  String get english => 'English';
  String get chinese => '中文';

  String get clearAllDataTitle => _t('Clear All Local Data', '清空本地数据');
  String get clearAllDataBody => _t(
    'This will permanently remove all local food, workout, and profile data. Continue?',
    '这会永久删除本地所有饮食、训练和资料数据。是否继续？',
  );

  String get clearData => _t('Clear Data', '清空数据');

  String get profileSaved => _t('Profile saved.', '资料已保存。');
  String get allDataCleared => _t('All local data cleared.', '本地数据已清空。');

  String get ageMinorNoDeficit => _t(
    'Age under 18 cannot use deficit target. Switched to maintenance.',
    '18 岁以下不支持赤字目标，已切换为维持。',
  );

  String get aggressiveGoalWarning => _t(
    'This deficit may be too aggressive. Prioritize long-term health.',
    '该目标可能比较激进，建议以健康和长期可持续为主。',
  );

  String get minorReminder => _t(
    'For users under 18, no weight-loss recommendation is shown.',
    '年龄小于 18 岁时不提供减重建议，仅记录与展示数据。',
  );

  String get saveProfile => _t('Save Profile', '保存资料');
  String get saveChanges => _t('Save Changes', '保存修改');
  String get save => _t('Save', '保存');
  String get maintenance => _t('Maintenance', '维持');
  String get deficit => _t('Deficit', '赤字');
  String get surplus => _t('Surplus', '盈余');
  String get male => _t('Male', '男');
  String get female => _t('Female', '女');
  String get preferNot => _t('Prefer not to say', '不透露');
  String get sedentary => _t('Sedentary', '久坐');
  String get lightlyActive => _t('Lightly Active', '轻度活跃');
  String get moderatelyActive => _t('Moderately Active', '中度活跃');
  String get veryActive => _t('Very Active', '高度活跃');
  String get enterValidAge => _t('Enter valid age', '请输入有效年龄');
  String get enterValidHeight => _t('Enter valid height', '请输入有效身高');
  String get enterValidWeight => _t('Enter valid weight', '请输入有效体重');

  String get noWorkoutRecords => _t(
    'No workout sessions yet. Tap Add Workout to begin.',
    '还没有训练记录，点击“添加训练”开始。',
  );

  String failedToLoadWorkout(Object error) =>
      _t('Failed to load workout records: $error', '加载训练记录失败：$error');

  String get workoutDeleted => _t('Workout deleted.', '训练记录已删除。');
  String get workoutPlan => _t('Workout Plan', '训练计划');
  String get workoutPlanList => _t('Workout Plans', '训练计划');
  String get startTimeLabel => _t('Start time', '开始时间');
  String get totalDurationLabel => _t('Total duration', '总时长');
  String get exerciseNamesLabel => _t('Exercises', '计划动作');
  String get actionsInPlan => _t('Actions in this plan', '本计划动作');
  String get noActionsInPlan => _t('No actions in this plan.', '该计划暂无动作。');

  String deleteWorkoutConfirm(String exerciseName, String date) =>
      _t('Delete $exerciseName on $date?', '确认删除 $date 的“$exerciseName”？');

  String deleteWorkoutPlanConfirm(int count, String date) => _t(
    'Delete this workout plan on $date? ($count exercises)',
    '确认删除 $date 这条训练计划？（共 $count 个动作）',
  );

  String get searchExercise => _t('Search exercise', '搜索动作');
  String get exercisesLibrary => _t('Exercise Library', '动作库');
  String get allBodyParts => _t('All muscle groups', '所有肌群');
  String get selectedExercise => _t('Selected Exercise', '已选动作');
  String get selectedExercises => _t('Selected Exercises', '已选动作计划');
  String selectedExercisesCount(int count) =>
      _t('$count selected', '已选 $count 个');
  String addExercisesWithCount(int count) =>
      _t('Add selected exercises ($count)', '添加已选动作（$count）');
  String get addExercises => _t('Add Exercises', '添加运动');
  String get exercisePlanDetails => _t('Exercise Plan Details', '动作计划详情');
  String get exercisePickerCollapsedHint => _t(
    'Exercise library is hidden by default. Tap the button to select multiple exercises.',
    '动作库默认折叠，点击按钮后可进入动作库一次多选。',
  );
  String get noExerciseSelectedYet =>
      _t('No exercise selected yet.', '还没有选择动作。');
  String get tapAddExerciseToBuildPlan => _t(
    'Tap Add Exercises to build your workout plan first.',
    '先点击“添加运动”，再填写每个动作的详细信息。',
  );
  String get tapExerciseToBuildPlan => _t(
    'Tap exercises above to build a multi-exercise workout plan.',
    '在上方点选动作，即可建立一个包含多个动作的训练计划。',
  );
  String get workoutDetails => _t('Workout Details', '训练参数');
  String get setsPlan => _t('Sets Plan', '组数计划');
  String setLabel(int index) => _t('Set #$index', '第 $index 组');
  String get weightKgShortLabel => _t('Weight (kg)', '重量 (kg)');
  String get addedWeightKgShortLabel => _t('Added (kg)', '加重 (kg)');
  String get repsLabel => _t('Reps', '次数');
  String get addSet => _t('Add Set', '新增组');
  String get removeExercise => _t('Remove exercise', '移除动作');
  String get removeSet => _t('Remove set', '移除组');
  String get bodyweightAddedLoadHint => _t(
    'For bodyweight exercises, weight means added load. Enter 0 for bodyweight only.',
    '自重动作中“重量”表示额外加重；填 0 表示仅自重。',
  );
  String get completeBeforeSaveHint => _t(
    'You can mark completed sets before saving this plan.',
    '保存前可先勾选已完成组，便于训练中直接记录。',
  );
  String get cardioNoSetPlan =>
      _t('Cardio does not require set planning.', '有氧训练不需要设置组数。');
  String get cardioDurationHint => _t(
    'Cardio calories are calculated from duration and body weight. Set this movement duration separately.',
    '有氧消耗按时长和体重计算，请为每个有氧动作单独填写时长。',
  );
  String get strengthDurationNotice => _t(
    'Note: Strength calories here are net exercise calories. Inter-set rest baseline is not added. Long rest does not linearly increase calories.',
    '注意：力量训练这里按净额外消耗估算，不叠加组间静息基础消耗。长时间休息不会线性增加消耗。',
  );
  String usingProfileWeight(double weightKg) => _t(
    'Using profile weight: ${weightKg.toStringAsFixed(1)} kg',
    '使用资料体重：${weightKg.toStringAsFixed(1)} kg',
  );
  String get durationSplitHint => _t(
    'Duration will be distributed across selected exercises.',
    '总时长会分配到已选动作中用于估算。',
  );
  String get saveWorkout => _t('Save Workout', '保存训练');
  String workoutPlanSavedCount(int count) => _t(
    'Saved $count exercises in this workout plan.',
    '已保存本次计划中的 $count 个动作。',
  );
  String get workoutSaved => _t('Workout session saved.', '训练记录已保存。');
  String get chooseExercise => _t('Please choose an exercise.', '请选择一个动作。');
  String get chooseAtLeastOneExercise =>
      _t('Please select at least one exercise.', '请至少选择一个动作。');
  String get invalidDuration =>
      _t('Duration must be greater than 0.', '训练时长必须大于 0。');
  String invalidDurationForExercise(String exerciseName) => _t(
    'Please set duration > 0 for $exerciseName.',
    '请为“$exerciseName”填写大于 0 的时长。',
  );
  String invalidSetValue(String exerciseName) => _t(
    'Please check set values for $exerciseName.',
    '请检查“$exerciseName”的组数参数。',
  );
  String noSetsForExercise(String exerciseName) => _t(
    'Please add at least one set for $exerciseName.',
    '请至少为“$exerciseName”添加一组。',
  );

  String get completeSet => _t('Complete Set', '完成本组');
  String get completed => _t('Completed', '已完成');

  String get todayFoodList => _t('Today Food Records', '今日食物记录');
  String get todayWorkoutList => _t('Today Workout Records', '今日训练记录');

  String get caloriesInTodayLabel => _t('Calories in today', '今日摄入热量');
  String todayCaloriesAux(double caloriesIn) => _t(
    'Today intake: ${caloriesIn.toStringAsFixed(0)} kcal',
    '今日已摄入：${caloriesIn.toStringAsFixed(0)} kcal',
  );
  String get exerciseCaloriesTodayLabel =>
      _t('Exercise calories today', '今日运动消耗');
  String get targetIntakeLabel => _t('Target intake', '今日目标摄入');
  String get remainingCaloriesLabel => _t('Remaining calories', '剩余热量');
  String get macroTargetModeGramPerKg =>
      _t('Macro Targets (g/kg)', '三大营养目标（g/kg）');
  String get gramPerKgModeNotice => _t(
    'g/kg mode uses bodyweight, sex, training-frequency tier, and the current phase table only. It does not mix with calorie deficit or surplus math; kcal is auxiliary.',
    'g/kg 模式只按体重、性别、训练频率档位和当前阶段表计算，不与热量赤字或盈余算法混合；kcal 仅作辅助信息。',
  );
  String phaseLabel(String phase) {
    switch (phase) {
      case 'bulking':
        return bulkingLabel;
      case 'cutting':
      default:
        return cuttingLabel;
    }
  }

  String gramPerKgTableTitle(String phase) {
    return phase == 'bulking'
        ? _t('Bulking g/kg table', '增肌期 g/kg 表')
        : _t('Cutting g/kg table', '减脂期 g/kg 表');
  }

  String gramPerKgPhaseNotice(String phase) {
    return phase == 'bulking'
        ? _t(
            'This is the bulking g/kg default table. It gives macro targets directly from bodyweight, sex, and training frequency, without mixing in calorie surplus math.',
            '这是增肌期 g/kg 默认表。它直接按体重、性别和训练频率给出宏量目标，不与热量盈余算法混合计算。',
          )
        : _t(
            'This is the cutting g/kg default table. Carbohydrate coefficients are tuned for cutting and are not a bulking or performance-maximization table.',
            '这是减脂期 g/kg 默认表。碳水系数已按减脂场景调整，不是增肌期表，也不是运动表现最大化表。',
          );
  }

  String energyRatioPhaseNotice(String phase) {
    return phase == 'bulking'
        ? _t(
            'Uses BMR, non-exercise lifestyle factor, daily calorie surplus, and logged net exercise to calculate target kcal.',
            '按 BMR、非运动活动系数、每日热量盈余和当天已记录净运动消耗计算目标 kcal。',
          )
        : _t(
            'Uses BMR, non-exercise lifestyle factor, daily calorie deficit, and logged net exercise to calculate target kcal.',
            '按 BMR、非运动活动系数、每日热量赤字和当天已记录净运动消耗计算目标 kcal。',
          );
  }
  String get macroEquivalentEnergyLabel =>
      _t('Macro equivalent energy', '三大营养换算能量');
  String get proteinLabel => _t('Protein', '蛋白质');
  String get carbsLabel => _t('Carbs', '碳水');
  String get fatLabel => _t('Fat', '脂肪');
  String get remainingProteinLabel => _t('Protein remaining (g)', '蛋白质剩余 (g)');
  String get remainingCarbsLabel => _t('Carbs remaining (g)', '碳水剩余 (g)');
  String get remainingFatLabel => _t('Fat remaining (g)', '脂肪剩余 (g)');
  String get tdeeReferenceLabel =>
      _t('No-exercise baseline TDEE', '不运动基线 TDEE');
  String get lifestyleFactorLabel =>
      _t('Lifestyle factor (non-exercise)', '日常活动系数（不含专项训练）');
  String get calibrationConfidenceLabel =>
      _t('Calibration confidence', '校准置信度');
  String get calibrationWindowLabel => _t('Calibration window', '校准窗口');
  String get todayExerciseCaloriesLabel =>
      _t('Today exercise calories', '今日运动消耗');
  String get targetIntakeTodayLabel => _t('Target intake today', '今日目标摄入');
  String get remainingTodayLabel => _t('Remaining today', '今日剩余');

  String get noSummaryData => _t('No summary data.', '暂无汇总数据。');
  String summaryError(Object error) =>
      _t('Failed to load summary: $error', '加载汇总失败：$error');

  String get nearTarget => _t('Today is close to target', '今日接近目标');

  String remainingCanEat(double kcal) => _t(
    'You can still eat about ${kcal.toStringAsFixed(0)} kcal today',
    '今日距离目标还可摄入约 ${kcal.toStringAsFixed(0)} kcal',
  );

  String remainingExceeded(double kcal) => _t(
    'You exceeded target by about ${kcal.toStringAsFixed(0)} kcal today',
    '今日已超过目标约 ${kcal.toStringAsFixed(0)} kcal',
  );

  String bodyPartLabel(String bodyPart) {
    const map = <String, String>{
      'Chest': '胸部',
      'Back': '背部',
      'Legs': '腿部',
      'Shoulders': '肩部',
      'Arms': '手臂',
      'Core': '核心',
      'Cardio': '有氧',
      'Full Body': '全身',
    };
    if (!isChinese) {
      return bodyPart;
    }
    return map[bodyPart] ?? bodyPart;
  }

  String exerciseDisplayName(String exerciseName) {
    if (!isChinese) {
      return exerciseName;
    }

    const map = <String, String>{
      'Bench Press': '卧推',
      'Incline Dumbbell Press': '上斜哑铃卧推',
      'Push-up': '俯卧撑',
      'Chest Fly': '飞鸟',
      'Pull-up': '引体向上',
      'Lat Pulldown': '高位下拉',
      'Barbell Row': '杠铃划船',
      'Seated Cable Row': '坐姿划船',
      'Squat': '深蹲',
      'Leg Press': '腿举',
      'Romanian Deadlift': '罗马尼亚硬拉',
      'Leg Extension': '腿屈伸',
      'Leg Curl': '腿弯举',
      'Overhead Press': '推举',
      'Lateral Raise': '侧平举',
      'Rear Delt Fly': '反向飞鸟',
      'Biceps Curl': '二头弯举',
      'Triceps Pushdown': '三头下压',
      'Hammer Curl': '锤式弯举',
      'Plank': '平板支撑',
      'Crunch': '卷腹',
      'Hanging Leg Raise': '悬垂举腿',
      'Running': '跑步',
      'Walking': '步行',
      'Cycling': '骑行',
      'Rowing Machine': '划船机',
      'Stair Climber': '登阶机',
      'Deadlift': '硬拉',
      'Kettlebell Swing': '壶铃摆动',
      'Burpee': '波比跳',
    };

    return map[exerciseName] ?? exerciseName;
  }

  String get loading => _t('Loading...', '加载中...');
  String get saving => _t('Saving...', '保存中...');

  String sexOptionLabel(String value) {
    switch (value) {
      case 'male':
        return male;
      case 'female':
        return female;
      case 'prefer_not_to_say':
      default:
        return preferNot;
    }
  }

  String activityOptionLabel(String value) {
    switch (value) {
      case 'sedentary':
        return sedentary;
      case 'lightly_active':
        return lightlyActive;
      case 'very_active':
        return veryActive;
      case 'moderately_active':
      default:
        return moderatelyActive;
    }
  }

  String goalTypeLabel(String value) {
    switch (value) {
      case 'deficit':
        return deficit;
      case 'surplus':
        return surplus;
      case 'maintenance':
      default:
        return maintenance;
    }
  }

  String intensityLabel(String intensity) {
    switch (intensity) {
      case 'low':
        return _t('Low', '低');
      case 'high':
        return _t('High', '高');
      case 'medium':
      default:
        return _t('Medium', '中');
    }
  }

  String setPerformanceLabel({
    required double weightKg,
    required int reps,
    required bool isBodyweightExercise,
  }) {
    if (isBodyweightExercise) {
      if (weightKg <= 0) {
        return _t('Bodyweight - Reps $reps', '自重 - $reps 次');
      }
      return _t(
        'Bodyweight +${weightKg.toStringAsFixed(1)} kg - Reps $reps',
        '自重 +${weightKg.toStringAsFixed(1)} kg - $reps 次',
      );
    }

    return _t(
      'Weight ${weightKg.toStringAsFixed(1)} kg - Reps $reps',
      '重量 ${weightKg.toStringAsFixed(1)} kg - $reps 次',
    );
  }
}
