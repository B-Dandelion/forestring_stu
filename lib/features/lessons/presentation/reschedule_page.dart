import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lesson.dart';
import 'lesson_controller.dart';
import 'student_my_page.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String? _selectedLessonId;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  LessonBookingWindow? _window;
  List<LessonBookingOption> _options = const [];
  bool _loadingWindow = false;
  bool _loadingOptions = false;
  bool _booking = false;
  String? _errorMessage;
  bool _initialized = false;
  int _loadToken = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final canceled = context.read<LessonController>().canceledLessons;
      if (canceled.isNotEmpty) {
        _selectLesson(canceled.first);
      }
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampToWindow(DateTime date, LessonBookingWindow window) {
    final value = _dateOnly(date);
    final start = _dateOnly(window.startsOn);
    final end = _dateOnly(window.endsOn);
    if (value.isBefore(start)) {
      return start;
    }
    if (value.isAfter(end)) {
      return end;
    }
    return value;
  }

  Future<void> _selectLesson(Lesson lesson) async {
    final token = ++_loadToken;
    setState(() {
      _selectedLessonId = lesson.id;
      _window = null;
      _options = const [];
      _loadingWindow = true;
      _loadingOptions = false;
      _errorMessage = null;
    });

    try {
      final controller = context.read<LessonController>();
      final window = await controller.getBookingWindow(lesson);
      if (!mounted || token != _loadToken) {
        return;
      }

      final selectedDate = _clampToWindow(lesson.startsAt, window);
      setState(() {
        _window = window;
        _selectedDate = selectedDate;
        _focusedDate = selectedDate;
        _loadingWindow = false;
      });
      await _loadOptions(lesson, selectedDate);
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _loadingWindow = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadOptions(Lesson lesson, DateTime date) async {
    final token = ++_loadToken;
    setState(() {
      _loadingOptions = true;
      _errorMessage = null;
      _options = const [];
    });

    try {
      final loaded = await context.read<LessonController>().getBookingOptions(
            lesson: lesson,
            selectedDate: date,
          );
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _options = loaded;
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _loadingOptions = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _book(
    Lesson lesson,
    LessonBookingOption option,
  ) async {
    if (_booking) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('수업 예약'),
            content: Text(
              '${DateFormat('M월 d일 HH:mm').format(option.startsAt)} ~ '
              '${DateFormat('HH:mm').format(option.endsAt)}\n이 시간으로 예약하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('예약'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _booking = true;
    });

    final controller = context.read<LessonController>();
    final ok = await controller.bookLessonRight(
      lesson: lesson,
      option: option,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _booking = false;
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? '수업을 예약하지 못했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수업이 예약되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final remaining = controller.canceledLessons;
    if (remaining.isEmpty) {
      setState(() {
        _selectedLessonId = null;
        _window = null;
        _options = const [];
      });
    } else {
      await _selectLesson(remaining.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();
    final canceled = controller.canceledLessons;

    Lesson? selectedLesson;
    if (canceled.isNotEmpty) {
      selectedLesson = canceled.firstWhere(
        (lesson) => lesson.id == _selectedLessonId,
        orElse: () => canceled.first,
      );
      if (_selectedLessonId != selectedLesson.id && !_loadingWindow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _selectLesson(selectedLesson!);
          }
        });
      }
    }

    return Scaffold(
      appBar: const StudentAppBar(),
      drawer: StudentDrawer(
        displayName: widget.profile.displayName,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
        },
        onReschedule: () => Navigator.of(context).pop(),
        onMyPage: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<LessonController>(),
                child: StudentMyPage(profile: widget.profile),
              ),
            ),
          );
        },
        onLogout: () async {
          Navigator.of(context).pop();
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
      body: SafeArea(
        child: canceled.isEmpty
            ? RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    const Icon(
                      Icons.event_available_outlined,
                      size: 52,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '재예약할 수업이 없습니다.',
                      textAlign: TextAlign.center,
                      style: forestringTextStyle.copyWith(fontSize: 17),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: DropdownButtonFormField<String>(
                      value: selectedLesson?.id,
                      decoration: const InputDecoration(
                        labelText: '재예약할 수업',
                        border: OutlineInputBorder(),
                      ),
                      items: canceled
                          .map(
                            (lesson) => DropdownMenuItem<String>(
                              value: lesson.id,
                              child: Text(
                                '${DateFormat('M월 d일 HH:mm').format(lesson.startsAt)} '
                                '· ${lesson.durationMinutes}분',
                                style: forestringTextStyle,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingWindow || _booking
                          ? null
                          : (id) {
                              if (id == null) {
                                return;
                              }
                              final lesson = canceled.firstWhere(
                                (item) => item.id == id,
                              );
                              _selectLesson(lesson);
                            },
                    ),
                  ),
                  if (_loadingWindow)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_window != null && selectedLesson != null) ...[
                    TableCalendar<void>(
                      firstDay: _dateOnly(_window!.startsOn),
                      lastDay: _dateOnly(_window!.endsOn),
                      focusedDay: _focusedDate,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _focusedDate = focusedDay;
                        });
                        _loadOptions(selectedLesson!, selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDate = focusedDay;
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextFormatter: (date, locale) => '${date.month}월',
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: primaryColor,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: primaryColor,
                        ),
                        titleTextStyle: const TextStyle(
                          fontFamily: 'ELAND',
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          color: primaryColor,
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: secondaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        dowBuilder: (context, day) {
                          final label = _weekdayLabels[day.weekday - 1];
                          return Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'ELAND',
                                fontWeight: FontWeight.w500,
                                color: day.weekday == DateTime.sunday
                                    ? Colors.red
                                    : day.weekday == DateTime.saturday
                                        ? Colors.blue
                                        : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ivoryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${DateFormat('M월 d일').format(_selectedDate)} 예약 가능 시간',
                        style: forestringTextStyle.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _loadingOptions
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: forestringTextStyle.copyWith(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                )
                              : _options.isEmpty
                                  ? Center(
                                      child: Text(
                                        '예약 가능한 시간이 없습니다.',
                                        style: forestringTextStyle.copyWith(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        4,
                                        12,
                                        24,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisExtent: 48,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                      ),
                                      itemCount: _options.length,
                                      itemBuilder: (context, index) {
                                        final option = _options[index];
                                        return OutlinedButton(
                                          onPressed: _booking
                                              ? null
                                              : () => _book(
                                                    selectedLesson!,
                                                    option,
                                                  ),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Text(
                                            DateFormat('HH:mm')
                                                .format(option.startsAt),
                                            style: forestringTextStyle.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ] else
                    Expanded(
                      child: Center(
                        child: Text(
                          _errorMessage ?? '예약 정보를 불러오지 못했습니다.',
                          style: forestringTextStyle.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
