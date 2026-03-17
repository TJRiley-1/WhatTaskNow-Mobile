import '../models/task.dart';

class TaskTemplate {
  final String name;
  final String type;
  final int time;
  final Level energy;
  final Level social;

  const TaskTemplate({
    required this.name,
    required this.type,
    required this.time,
    required this.energy,
    required this.social,
  });
}

const _workTemplates = [
  TaskTemplate(name: 'Reply to one email', type: 'work', time: 5, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Tidy your desk for 10 minutes', type: 'work', time: 10, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Write a to-do list for the week', type: 'work', time: 15, energy: Level.medium, social: Level.low),
];

const _personalTemplates = [
  TaskTemplate(name: 'Put away 5 things', type: 'personal', time: 5, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Do one load of laundry', type: 'personal', time: 15, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Sort through that pile on the chair', type: 'personal', time: 10, energy: Level.low, social: Level.low),
];

const _healthTemplates = [
  TaskTemplate(name: 'Drink a glass of water', type: 'health', time: 5, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Go for a 10-minute walk', type: 'health', time: 10, energy: Level.medium, social: Level.low),
  TaskTemplate(name: 'Stretch for 5 minutes', type: 'health', time: 5, energy: Level.low, social: Level.low),
];

const _socialTemplates = [
  TaskTemplate(name: 'Text a friend back', type: 'social', time: 5, energy: Level.low, social: Level.medium),
  TaskTemplate(name: 'Call someone you keep meaning to', type: 'social', time: 15, energy: Level.medium, social: Level.high),
  TaskTemplate(name: 'Reply to that group chat', type: 'social', time: 5, energy: Level.low, social: Level.medium),
];

const _errandTemplates = [
  TaskTemplate(name: 'Take the bins out', type: 'errand', time: 5, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Go to the shop for one thing', type: 'errand', time: 15, energy: Level.medium, social: Level.low),
  TaskTemplate(name: 'Post that parcel', type: 'errand', time: 15, energy: Level.medium, social: Level.low),
];

const _otherTemplates = [
  TaskTemplate(name: 'Do one small thing you keep putting off', type: 'other', time: 10, energy: Level.low, social: Level.low),
  TaskTemplate(name: 'Set a timer and tidy for 5 minutes', type: 'other', time: 5, energy: Level.low, social: Level.low),
];

const _templatesByType = <String, List<TaskTemplate>>{
  'work': _workTemplates,
  'personal': _personalTemplates,
  'health': _healthTemplates,
  'social': _socialTemplates,
  'errand': _errandTemplates,
  'other': _otherTemplates,
};

/// Returns up to [limit] template tasks based on the user's preferred categories.
/// Falls back to personal + other if no categories selected.
List<TaskTemplate> getTemplateSuggestions(List<String>? categories, {int limit = 4}) {
  final cats = (categories != null && categories.isNotEmpty)
      ? categories
      : ['personal', 'other'];

  final templates = <TaskTemplate>[];
  for (final cat in cats) {
    templates.addAll(_templatesByType[cat] ?? []);
  }

  // Shuffle and limit
  final shuffled = List<TaskTemplate>.from(templates)..shuffle();
  return shuffled.take(limit).toList();
}
