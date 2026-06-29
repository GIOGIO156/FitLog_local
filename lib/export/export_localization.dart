import '../core/constants/app_constants.dart';
import '../core/constants/exercise_definition.dart';
import '../core/localization/app_language.dart';
import '../core/localization/app_strings.dart';

class ExportLocalization {
  ExportLocalization(AppLanguage language) : strings = AppStrings(language);

  final AppStrings strings;

  bool get isChinese => strings.isChinese;

  String sheetName(String tableId) {
    if (isChinese) {
      return _zhTableNames[tableId] ?? tableId;
    }
    return _enTableNames[tableId] ?? tableId;
  }

  String fileName(String tableId) {
    if (isChinese) {
      return '${_zhTableNames[tableId] ?? tableId}.csv';
    }
    return '$tableId.csv';
  }

  List<List<dynamic>> localizeRows(String tableId, List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return rows;
    }

    final columns = rows.first.map((value) => value.toString()).toList();
    return <List<dynamic>>[
      columns.map((key) => header(tableId, key)).toList(),
      for (final row in rows.skip(1))
        <dynamic>[
          for (var i = 0; i < columns.length; i++)
            localizeValue(columns[i], i < row.length ? row[i] : ''),
        ],
    ];
  }

  String header(String tableId, String key) {
    if (isChinese) {
      final tableHeader = _zhTableHeaderOverrides[tableId]?[key];
      if (tableHeader != null) {
        return tableHeader;
      }
      return _zhHeaders[key] ?? key;
    }
    return _enHeaders[key] ?? key;
  }

  dynamic localizeValue(String key, dynamic value) {
    if (!isChinese || value == null) {
      return value;
    }

    final raw = value.toString();
    if (raw.isEmpty) {
      return value;
    }

    switch (key) {
      case 'source':
        return _sourceLabel(raw);
      case 'body_part':
      case 'secondary_body_part':
        return strings.bodyPartLabel(raw);
      case 'exercise_name':
        return strings.exerciseDisplayName(raw);
      case 'exercise_type':
        return _exerciseTypeLabel(raw);
      case 'exercise_source':
        return _exerciseSourceLabel(raw);
      case 'strength_structure':
        return _strengthStructureLabel(raw);
      case 'strength_profile':
        return _strengthProfileLabel(raw);
      case 'intensity':
        return strings.intensityLabel(raw);
      case 'default_cardio_intensity':
      case 'cardio_intensity_basis':
        return strings.cardioIntensityOptionLabel(raw);
      case 'load_input_mode':
        return strings.loadInputModeLabel(raw);
      case 'reps_input_mode':
        return strings.repsInputModeLabel(raw);
      case 'set_metric_type':
        return strings.setMetricTypeLabel(raw);
      case 'sex_for_formula':
        return strings.sexOptionLabel(raw);
      case 'activity_level':
        return strings.activityOptionLabel(raw);
      case 'daily_energy_goal_type':
        return strings.goalTypeLabel(raw);
      case 'diet_goal_phase':
        return strings.phaseLabel(raw);
      case 'diet_calculation_mode':
        return _dietCalculationModeLabel(raw);
      case 'diet_plan_strategy':
        return strings.strategyLabel(raw);
      case 'carb_day_type':
        return strings.carbDayTypeLabel(raw);
      case 'suggested_action':
        return strings.carbTaperReviewActionLabel(raw);
      case 'user_decision':
        return _dietAdjustmentDecisionLabel(raw);
      case 'is_hidden':
      case 'is_completed':
      case 'is_energy_target_mode':
      case 'macro_self_check_enabled':
      case 'macro_self_check_should_suggest':
      case 'macro_self_check_has_valid_training_data':
      case 'macro_self_check_below_recommended_range':
        return _yesNo(value);
    }

    return value;
  }

  String exerciseName(String name) => strings.exerciseDisplayName(name);

  String _yesNoLabel(bool value) {
    if (!isChinese) {
      return value ? '1' : '0';
    }
    return value ? '是' : '否';
  }

  String _yesNo(dynamic value) {
    final isTrue = value == true || value == 1 || value.toString() == '1';
    return _yesNoLabel(isTrue);
  }

  String _sourceLabel(String value) {
    switch (value) {
      case 'profile_save':
        return '资料保存';
      case 'body_metric_manual':
        return '手动身体指标';
      case 'manual':
      case 'ai_paste':
        return strings.sourceLabel(value);
      default:
        return value;
    }
  }

  String _exerciseTypeLabel(String value) {
    switch (value) {
      case ExerciseType.cardio:
        return '有氧';
      case ExerciseType.strength:
        return '力量';
      default:
        return value;
    }
  }

  String _exerciseSourceLabel(String value) {
    switch (value) {
      case ExerciseSource.builtin:
        return '内置';
      case ExerciseSource.custom:
        return '自定义';
      case ExerciseSource.adHoc:
        return '临时';
      default:
        return value;
    }
  }

  String _strengthStructureLabel(String value) {
    switch (value) {
      case ExerciseStructure.isolation:
      case ExerciseStructure.compound:
        return strings.exerciseStructureLabelFor(value);
      case ExerciseStructure.fullBodyAuto:
        return '全身自动';
      default:
        return value;
    }
  }

  String _strengthProfileLabel(String value) {
    switch (value) {
      case ExerciseStrengthProfile.upperBodyCompound:
        return '上肢复合';
      case ExerciseStrengthProfile.lowerBodyCompound:
        return '下肢复合';
      case ExerciseStrengthProfile.isolation:
        return '孤立动作';
      case ExerciseStrengthProfile.fullBodyPowerOrHighDensity:
        return '全身力量/高密度';
      default:
        return value;
    }
  }

  String _dietCalculationModeLabel(String value) {
    switch (value) {
      case AppConstants.dietCalculationModeGramPerKg:
        return strings.gramPerKgModeLabel;
      case AppConstants.dietCalculationModeEnergyRatio:
        return strings.energyRatioModeLabel;
      default:
        return value;
    }
  }

  String _dietAdjustmentDecisionLabel(String value) {
    switch (value) {
      case AppConstants.dietAdjustmentDecisionPending:
        return '待处理';
      case AppConstants.dietAdjustmentDecisionAccepted:
        return '已接受';
      case AppConstants.dietAdjustmentDecisionDismissed:
        return '已忽略';
      case AppConstants.dietAdjustmentDecisionExpired:
        return '已过期';
      default:
        return value;
    }
  }
}

const Map<String, String> _enTableNames = <String, String>{
  'food_records': 'Food Records',
  'food_items': 'Food Items',
  'workout_records': 'Workout Records',
  'workout_exercise_sets': 'Workout Exercise Sets',
  'custom_exercises': 'Custom Exercises',
  'daily_summary': 'Daily Summary',
  'user_profile': 'User Profile',
  'body_metric_logs': 'Body Metric Logs',
  'diet_adjustment_reviews': 'Diet Adjustment Reviews',
};

const Map<String, String> _zhTableNames = <String, String>{
  'food_records': '饮食记录',
  'food_items': '食物明细',
  'workout_records': '训练记录',
  'workout_exercise_sets': '训练动作明细',
  'custom_exercises': '自定义动作',
  'daily_summary': '每日汇总',
  'user_profile': '用户资料',
  'body_metric_logs': '身体指标记录',
  'diet_adjustment_reviews': '饮食调整复盘',
};

const Map<String, String> _enHeaders = <String, String>{
  'workout_record_id': 'workout_record_id',
  'workout_session_id': 'workout_session_id',
  'exercise_order': 'exercise_order',
  'total_duration_minutes': 'total_duration_minutes',
  'total_volume_kg': 'total_volume_kg',
  'total_sets': 'total_sets',
  'exercise_count': 'exercise_count',
  'exercise_names': 'exercise_names',
};

const Map<String, Map<String, String>> _zhTableHeaderOverrides =
    <String, Map<String, String>>{
      'food_items': <String, String>{'name': '食物名称'},
      'custom_exercises': <String, String>{'name': '动作名称'},
      'user_profile': <String, String>{'weight_kg': '体重_kg'},
      'body_metric_logs': <String, String>{'weight_kg': '体重_kg'},
      'workout_exercise_sets': <String, String>{'weight_kg': '重量_kg'},
    };

const Map<String, String> _zhHeaders = <String, String>{
  'date': '日期',
  'food_record_id': '饮食记录ID',
  'meal_name': '餐食名称',
  'total_weight_g': '总重量_g',
  'calories_kcal': '热量_kcal',
  'protein_g': '蛋白质_g',
  'carbs_g': '碳水_g',
  'fat_g': '脂肪_g',
  'confidence': '置信度',
  'source': '来源',
  'estimation_notes': '估算说明',
  'name': '名称',
  'estimated_weight_g': '估算重量_g',
  'notes': '备注',
  'workout_record_id': '训练记录ID',
  'workout_session_id': '动作记录ID',
  'record_name': '训练名称',
  'total_duration_minutes': '总时长_分钟',
  'total_volume_kg': '总运动量_kg',
  'total_sets': '总组数',
  'estimated_calories': '估算消耗_kcal',
  'exercise_count': '动作数量',
  'exercise_names': '记录动作',
  'exercise_order': '动作顺序',
  'exercise_key': '动作Key',
  'exercise_source': '动作来源',
  'exercise_name': '动作名',
  'exercise_type': '动作类型',
  'body_part': '部位',
  'secondary_body_part': '辅助部位',
  'duration_minutes': '时长_分钟',
  'intensity': '强度',
  'strength_profile': '力量配置',
  'load_input_mode': '重量填写方式',
  'reps_input_mode': '次数填写方式',
  'set_metric_type': '组记录方式',
  'cardio_met': '有氧MET',
  'cardio_intensity_basis': '有氧强度依据',
  'cardio_active_minutes': '有氧实际运动分钟',
  'body_weight_kg_at_calculation': '计算时体重_kg',
  'exercise_snapshot_json': '动作快照_JSON',
  'set_number': '组号',
  'weight_kg': '重量_kg',
  'reps': '次数',
  'input_weight_kg': '原始输入重量_kg',
  'input_reps': '原始输入次数',
  'input_duration_seconds': '原始输入时长_秒',
  'calculation_load_kg': '计算重量_kg',
  'calculation_reps': '计算次数',
  'is_completed': '是否完成',
  'completed_at': '完成时间',
  'strength_structure': '力量动作结构',
  'default_cardio_intensity': '默认有氧强度',
  'is_hidden': '是否隐藏',
  'nickname': '昵称',
  'age': '年龄',
  'height_cm': '身高_cm',
  'body_fat_percent': '体脂率_%',
  'waist_cm': '腰围_cm',
  'sex_for_formula': '公式性别',
  'activity_level': '活动水平',
  'daily_energy_goal_type': '每日热量目标类型',
  'daily_energy_goal_kcal': '每日热量目标_kcal',
  'protein_ratio_percent': '蛋白质比例_%',
  'carbs_ratio_percent': '碳水比例_%',
  'fat_ratio_percent': '脂肪比例_%',
  'diet_goal_phase': '饮食目标阶段',
  'diet_calculation_mode': '饮食计算方式',
  'diet_plan_strategy': '饮食策略',
  'carb_cycle_pattern_json': '碳水循环安排_JSON',
  'carb_cycle_high_multiplier': '高碳日倍率',
  'carb_cycle_medium_multiplier': '中碳日倍率',
  'carb_cycle_low_multiplier': '低碳日倍率',
  'carb_taper_review_period_days': '碳水递减复盘周期_天',
  'carb_taper_target_loss_pct_per_week': '目标周减重率_%',
  'carb_taper_step_g': '碳水递减步长_g',
  'carb_taper_current_delta_g': '当前碳水调整_g',
  'last_carb_taper_review_at': '上次碳水递减复盘时间',
  'training_frequency_per_week': '每周训练频率',
  'macro_self_check_period_days': '宏量自检周期_天',
  'macro_self_check_enabled': '是否启用宏量自检',
  'last_macro_self_check_at': '上次宏量自检时间',
  'carb_day_type': '碳水日类型',
  'is_energy_target_mode': '是否热量目标模式',
  'calories_in': '摄入热量_kcal',
  'exercise_calories': '运动消耗_kcal',
  'bmr': 'BMR',
  'tdee_reference': 'TDEE参考',
  'lifestyle_factor_used': '使用的生活系数',
  'no_exercise_target_intake': '无运动目标摄入_kcal',
  'target_intake': '目标摄入_kcal',
  'remaining_calories': '剩余热量_kcal',
  'base_target_calories': '基础目标热量_kcal',
  'base_protein_target_g': '基础蛋白质目标_g',
  'base_carbs_target_g': '基础碳水目标_g',
  'base_fat_target_g': '基础脂肪目标_g',
  'final_target_calories': '最终目标热量_kcal',
  'final_protein_target_g': '最终蛋白质目标_g',
  'final_carbs_target_g': '最终碳水目标_g',
  'final_fat_target_g': '最终脂肪目标_g',
  'carb_adjustment_g': '碳水调整_g',
  'calibration_confidence': '校准置信度',
  'calibration_window_days': '校准窗口_天',
  'calibration_valid_days': '校准有效天数',
  'target_protein_g': '目标蛋白质_g',
  'target_carbs_g': '目标碳水_g',
  'target_fat_g': '目标脂肪_g',
  'remaining_protein_g': '剩余蛋白质_g',
  'remaining_carbs_g': '剩余碳水_g',
  'remaining_fat_g': '剩余脂肪_g',
  'base_macro_energy_equivalent_kcal': '基础宏量折算热量_kcal',
  'final_macro_energy_equivalent_kcal': '最终宏量折算热量_kcal',
  'macro_energy_equivalent_kcal': '宏量折算热量_kcal',
  'diet_strategy_reason_codes': '饮食策略原因代码',
  'macro_self_check_current_frequency': '自检当前频率',
  'macro_self_check_recommended_frequency': '自检推荐频率',
  'macro_self_check_active_training_days': '自检有效训练天数',
  'macro_self_check_average_weekly_frequency': '自检平均周频率',
  'macro_self_check_should_suggest': '自检是否建议调整',
  'macro_self_check_has_valid_training_data': '自检是否有有效训练数据',
  'macro_self_check_below_recommended_range': '自检是否低于推荐范围',
  'review_date': '复盘日期',
  'window_days': '窗口天数',
  'start_avg_weight_kg': '起始平均体重_kg',
  'end_avg_weight_kg': '结束平均体重_kg',
  'weight_change_kg': '体重变化_kg',
  'loss_rate_pct_per_week': '周减重率_%',
  'target_loss_pct_per_week': '目标周减重率_%',
  'food_log_coverage': '饮食记录覆盖率',
  'active_training_days': '有效训练天数',
  'suggested_action': '建议动作',
  'suggested_carb_delta_g': '建议碳水调整_g',
  'applied_delta_after_g': '应用后碳水调整_g',
  'reason_codes_json': '原因代码_JSON',
  'user_decision': '用户决定',
};
