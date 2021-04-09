import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_date_pickers/src/date_period.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Color and setups
const Color _selectedDayItemBackgroundColor = Color(0xFF6547AD);
const Color _rangeItemsBackgroundColor = Color(0xFF291D47);
const Color _currentDayTextColor = Colors.white;
const Color _selectedDayTextColor = Colors.white;
const Color _disabledDayTextColor = Colors.white12;
const Color _headerDayNameTextColor = Color(0xFFFF6F71);
const Color _calendarBackgroundColor = Color(0xFF47327A);
const bool _isHeaderShow = false;
const double _monthNamePaddingTopBottom = 21.0;
// Height of Item in Calendar
const double _kDayPickerRowHeight = 52.0;

/// Initial display mode of the date picker dialog.
///
/// Date picker UI mode for either showing a list of available years or a
/// monthly calendar initially in the dialog shown by calling [showDatePicker].
///
/// Also see:
///
///  * <https://material.io/guidelines/components/pickers.html#pickers-date-pickers>
enum DatePickerMode {
  /// Show a date picker UI for choosing a month and day.
  day,

  /// Show a date picker UI for choosing a year.
  year,
}

const double _kDatePickerHeaderPortraitHeight = 72.0;
const double _kDatePickerHeaderLandscapeWidth = 168.0;

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight =
    _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

const double _kMonthPickerPortraitWidth = 330.0;
const double _kMonthPickerLandscapeWidth = 344.0;

const double _kDialogActionBarHeight = 52.0;
const double _kDatePickerLandscapeHeight =
    _kMaxDayPickerHeight + _kDialogActionBarHeight;

// Shows the selected date in large font and toggles between year and day mode
class _DatePickerHeader extends StatelessWidget {
  const _DatePickerHeader({
    Key key,
    @required this.selectedFirstDate,
    this.selectedLastDate,
    @required this.mode,
    @required this.onModeChanged,
    @required this.orientation,
  })  : assert(selectedFirstDate != null),
        assert(mode != null),
        assert(orientation != null),
        super(key: key);

  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;
  final DatePickerMode mode;
  final ValueChanged<DatePickerMode> onModeChanged;
  final Orientation orientation;

  void _handleChangeMode(DatePickerMode value) {
    if (value != mode) onModeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);
    final TextTheme headerTextTheme = themeData.primaryTextTheme;
    Color dayColor;
    Color yearColor;
    switch (themeData.primaryColorBrightness) {
      case Brightness.light:
        dayColor = mode == DatePickerMode.day ? Colors.black87 : Colors.black54;
        yearColor =
        mode == DatePickerMode.year ? Colors.black87 : Colors.black54;
        break;
      case Brightness.dark:
        dayColor = mode == DatePickerMode.day ? Colors.white : Colors.white70;
        yearColor = mode == DatePickerMode.year ? Colors.white : Colors.white70;
        break;
    }
    final TextStyle dayStyle =
    headerTextTheme.display1.copyWith(color: dayColor, height: 1.4);
    final TextStyle yearStyle =
    headerTextTheme.subhead.copyWith(color: yearColor, height: 1.4);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    double width;
    double height;
    EdgeInsets padding;
    switch (orientation) {
      case Orientation.portrait:
        width = _kMonthPickerPortraitWidth;
        height = _kDatePickerHeaderPortraitHeight;
        padding = const EdgeInsets.symmetric(horizontal: 8.0);
        break;
      case Orientation.landscape:
        height = _kDatePickerLandscapeHeight;
        width = _kDatePickerHeaderLandscapeWidth;
        padding = const EdgeInsets.all(8.0);
        break;
    }
    Widget renderYearButton(date) {
      return new IgnorePointer(
        ignoring: mode != DatePickerMode.day,
        ignoringSemantics: false,
        child: new _DateHeaderButton(
          color: backgroundColor,
          onTap: Feedback.wrapForTap(
                  () => _handleChangeMode(DatePickerMode.year), context),
          child: new Semantics(
              selected: mode == DatePickerMode.year,
              child:
              new Text(localizations.formatYear(date), style: yearStyle)),
        ),
      );
    }

    Widget renderDayButton(date) {
      return new IgnorePointer(
        ignoring: mode == DatePickerMode.day,
        ignoringSemantics: false,
        child: new _DateHeaderButton(
          color: backgroundColor,
          onTap: Feedback.wrapForTap(
                  () => _handleChangeMode(DatePickerMode.day), context),
          child: new Semantics(
              selected: mode == DatePickerMode.day,
              child: new Text(
                localizations.formatMediumDate(date),
                style: dayStyle,
                textScaleFactor: 0.5,
              )),
        ),
      );
    }

    final Widget startHeader = new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        renderYearButton(selectedFirstDate),
        renderDayButton(selectedFirstDate),
      ],
    );
    final Widget endHeader = selectedLastDate != null
        ? new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        renderYearButton(selectedLastDate),
        renderDayButton(selectedLastDate),
      ],
    )
        : new Container();

    return new Container(
      width: width,
      height: height,
      padding: padding,
      color: backgroundColor,
      child: orientation == Orientation.portrait
          ? new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [startHeader, endHeader],
      )
          : new Column(
        children: [
          new Container(
            width: width,
            child: startHeader,
          ),
          new Container(
            width: width,
            child: endHeader,
          ),
        ],
      ),
    );
  }
}

class _DateHeaderButton extends StatelessWidget {
  const _DateHeaderButton({
    Key key,
    this.onTap,
    this.color,
    this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new Material(
      type: MaterialType.button,
      color: color,
      child: new InkWell(
        borderRadius: kMaterialEdges[MaterialType.button],
        highlightColor: theme.highlightColor,
        splashColor: theme.splashColor,
        onTap: onTap,
        child: new Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: child,
        ),
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const double crossAxisSpacing = 0.5;
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_kDayPickerRowHeight,
        constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
    return new SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth - crossAxisSpacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// The day picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showDatePicker].
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class DayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [MonthPicker].
  DayPicker({
    Key key,
    @required this.selectedFirstDate,
    this.selectedLastDate,
    @required this.currentDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
    @required this.displayedMonth,
    this.selectableDayPredicate,
  })  : assert(selectedFirstDate != null),
        assert(currentDate != null),
        assert(onChanged != null),
        assert(displayedMonth != null),
        assert(!firstDate.isAfter(lastDate)),
        assert(!selectedFirstDate.isBefore(firstDate) &&
            (selectedLastDate == null || !selectedLastDate.isAfter(lastDate))),
        assert(selectedLastDate == null ||
            !selectedLastDate.isBefore(selectedFirstDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<List<DateTime>> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _getDayHeaders(
      TextStyle headerStyle, MaterialLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    // ignore: literal_only_boolean_expressions
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.narrowWeekdays[i];
      result.add(new ExcludeSemantics(
        child: new Center(child: new Text(weekday, style: headerStyle)),
      ));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return result;
  }

  // Do not use this directly - call getDaysInMonth instead.
  static const List<int> _daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];

  /// Returns the number of days in a month, according to the proleptic
  /// Gregorian calendar.
  ///
  /// This applies the leap year logic introduced by the Gregorian reforms of
  /// 1582. It will not give valid results for dates prior to that time.
  static int getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final bool isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      if (isLeapYear) return 29;
      return 28;
    }
    return _daysInMonth[month - 1];
  }

  /// Computes the offset from the first day of week that the first day of the
  /// [month] falls on.
  ///
  /// For example, September 1, 2017 falls on a Friday, which in the calendar
  /// localized for United States English appears as:
  ///
  /// ```
  /// S M T W T F S
  /// _ _ _ _ _ 1 2
  /// ```
  ///
  /// The offset for the first day of the months is the number of leading blanks
  /// in the calendar, i.e. 5.
  ///
  /// The same date localized for the Russian calendar has a different offset,
  /// because the first day of week is Monday rather than Sunday:
  ///
  /// ```
  /// M T W T F S S
  /// _ _ _ _ 1 2 3
  /// ```
  ///
  /// So the offset is 4, rather than 5.
  ///
  /// This code consolidates the following:
  ///
  /// - [DateTime.weekday] provides a 1-based index into days of week, with 1
  ///   falling on Monday.
  /// - [MaterialLocalizations.firstDayOfWeekIndex] provides a 0-based index
  ///   into the [MaterialLocalizations.narrowWeekdays] list.
  /// - [MaterialLocalizations.narrowWeekdays] list provides localized names of
  ///   days of week, always starting with Sunday and ending with Saturday.
  int _computeFirstDayOffset(
      int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week, with 0 representing Monday.
    final int weekdayFromMonday = new DateTime(year, month).weekday - 1;
    // 0-based day of week, with 0 representing Sunday.
    final int firstDayOfWeekFromSunday = localizations.firstDayOfWeekIndex;
    // firstDayOfWeekFromSunday recomputed to be Monday-based
    final int firstDayOfWeekFromMonday = (firstDayOfWeekFromSunday - 1) % 7;
    // Number of days between the first day of week appearing on the calendar,
    // and the day corresponding to the 1-st of the month.
    return (weekdayFromMonday - firstDayOfWeekFromMonday) % 7;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;
    final int daysInMonth = getDaysInMonth(year, month);
    final int firstDayOffset =
    _computeFirstDayOffset(year, month, localizations);
    final List<Widget> labels = <Widget>[];
    labels.addAll(_getDayHeaders(
        themeData.textTheme.caption.copyWith(
            color: _headerDayNameTextColor,
            fontFamily: "TTChocolatesDemiBold",
            fontSize: 16),
        localizations));
    // ignore: literal_only_boolean_expressions
    for (int i = 0; true; i += 1) {
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final int day = i - firstDayOffset + 1;
      developer.log('day: $day');
      developer.log('firstDayOffset: $firstDayOffset');
      developer.log('daysInMonth: $daysInMonth');
      // developer.log('i: $i');
      if (day > daysInMonth) break;
      bool isFirstDay = false;
      if (day == 1) {
        isFirstDay = true;
      }
      bool isLastDay = false;
      if (day == daysInMonth) {
        isLastDay = true;
      }
      bool isFirstFromLeftSide = false;
      if (i == 0 || i == 7 || i == 14 || i == 21 || i == 28 || i == 35) {
        isFirstFromLeftSide = true;
      }
      // developer.log('isFirstFromLeftSide: $isFirstFromLeftSide');
      bool isLastFromRightSide = false;
      if (i == 6 || i == 13 || i == 20 || i == 27 || i == 34) {
        isLastFromRightSide = true;
      }
      // developer.log('isLastFromRightSide: $isLastFromRightSide');
      if (day < 1) {
        labels.add(new Container());
      } else {
        final DateTime dayToBuild = new DateTime(year, month, day);
        final bool disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate(dayToBuild));
        BoxDecoration decoration;
        Color circleBackgroundColor = Colors.transparent;
        TextStyle itemStyle = themeData.textTheme.body1.copyWith(
            fontFamily: "TTChocolatesRegular",
            fontSize: 16,
            color: _selectedDayTextColor);
        final bool isSelectedFirstDay = selectedFirstDate.year == year &&
            selectedFirstDate.month == month &&
            selectedFirstDate.day == day;
        final bool isSelectedLastDay = selectedLastDate != null
            ? (selectedLastDate.year == year &&
            selectedLastDate.month == month &&
            selectedLastDate.day == day)
            : null;
        final bool isInRange = selectedLastDate != null
            ? (dayToBuild.isBefore(selectedLastDate) &&
            dayToBuild.isAfter(selectedFirstDate))
            : null;

        if (isSelectedFirstDay &&
            (isSelectedLastDay == null || isSelectedLastDay)) {
          // First Selected day
          itemStyle = themeData.textTheme.body2.copyWith(
              fontFamily: "TTChocolatesMedium",
              fontSize: 16,
              color: _selectedDayTextColor);
          decoration = new BoxDecoration(
              color: _selectedDayItemBackgroundColor, shape: BoxShape.circle);
        } else if (isSelectedFirstDay) {
          // First Selected day in Range
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = themeData.textTheme.body2.copyWith(
              fontFamily: "TTChocolatesMedium",
              fontSize: 16,
              color: _selectedDayTextColor);
          if (isFirstDay && isLastFromRightSide || isLastDay) {
          } else {
            decoration = new BoxDecoration(
                gradient: RainbowGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    _calendarBackgroundColor,
                    _rangeItemsBackgroundColor
                  ],
                ));
          }
          circleBackgroundColor = _selectedDayItemBackgroundColor;
        } else if (isSelectedLastDay != null && isSelectedLastDay) {
          // Last Selected day in Range
          itemStyle = themeData.textTheme.body2.copyWith(
              fontFamily: "TTChocolatesMedium",
              fontSize: 16,
              color: _selectedDayTextColor);
          if (isLastDay && isFirstFromLeftSide || isFirstDay) {
          } else {
            decoration = new BoxDecoration(
                gradient: RainbowGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    _rangeItemsBackgroundColor,
                    _calendarBackgroundColor
                  ],
                ));
          }
          circleBackgroundColor = _selectedDayItemBackgroundColor;
        } else if (isInRange != null && isInRange) {
          // Items in Range
          if (isFirstFromLeftSide) {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: new Radius.circular(50.0),
                  bottomLeft: new Radius.circular(50.0),
                ));
          } else if (isLastFromRightSide) {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor,
                borderRadius: BorderRadius.only(
                  topRight: new Radius.circular(50.0),
                  bottomRight: new Radius.circular(50.0),
                ));
          } else {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor, shape: BoxShape.rectangle);
          }
          if (isFirstDay) {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: new Radius.circular(50.0),
                  bottomLeft: new Radius.circular(50.0),
                ));
          }
          if (isFirstFromLeftSide && isLastDay ||
              isLastFromRightSide && isFirstDay) {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor,
                borderRadius: BorderRadius.only(
                  topRight: new Radius.circular(50.0),
                  bottomRight: new Radius.circular(50.0),
                  bottomLeft: new Radius.circular(50.0),
                  topLeft: new Radius.circular(50.0),
                ));
          } else if (isLastDay) {
            decoration = new BoxDecoration(
                color: _rangeItemsBackgroundColor,
                borderRadius: BorderRadius.only(
                    topRight: new Radius.circular(50.0),
                    bottomRight: new Radius.circular(50.0)));
          }
        } else if (disabled) {
          itemStyle = themeData.textTheme.body1.copyWith(
              fontFamily: "TTChocolatesRegular",
              fontSize: 16,
              color: _disabledDayTextColor);
        } else if (currentDate.year == year &&
            currentDate.month == month &&
            currentDate.day == day) {
          // The current day gets a different text color.
          itemStyle = themeData.textTheme.body1.copyWith(
              fontFamily: "TTChocolatesRegular",
              fontSize: 16,
              color: _selectedDayTextColor,
              fontWeight: FontWeight.bold);
        }

        Widget dayWidget = new Container(
          margin: const EdgeInsets.only(top: 3, bottom: 3, left: 0, right: 0),
          decoration: decoration,
          child: new Container(
            decoration: new BoxDecoration(
                color: circleBackgroundColor, shape: BoxShape.circle),
            child: new Center(
              child: new Semantics(
                // We want the day of month to be spoken first irrespective of the
                // locale-specific preferences or TextDirection. This is because
                // an accessibility user is more likely to be interested in the
                // day of month before the rest of the date, as they are looking
                // for the day of month. To do that we prepend day of month to the
                // formatted full date.
                label:
                '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
                selected: isSelectedFirstDay ||
                    isSelectedLastDay != null && isSelectedLastDay,
                child: new Container(
                  child: new ExcludeSemantics(
                    child: new Text(localizations.formatDecimal(day),
                        style: itemStyle),
                  ),
                ),
              ),
            ),
          ),
        );

        if (!disabled) {
          dayWidget = new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              DateTime first, last;
              if (selectedLastDate != null) {
                first = dayToBuild;
                last = null;
              } else {
                if (dayToBuild.compareTo(selectedFirstDate) <= 0) {
                  first = dayToBuild;
                  last = selectedFirstDate;
                } else {
                  first = selectedFirstDate;
                  last = dayToBuild;
                }
              }
              onChanged([first, last]);
            },
            child: dayWidget,
          );
        }

        labels.add(dayWidget);
      }
    }

    // Calendar arrow month name
    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Column(
        children: <Widget>[
          new Container(
            height: _kDayPickerRowHeight,
            child: new Center(
              child: new ExcludeSemantics(
                child: new Text(localizations.formatMonthYear(displayedMonth),
                    style: themeData.textTheme.body1.copyWith(
                        fontFamily: "TTChocolatesDemiBold",
                        fontSize: 16,
                        color: _selectedDayTextColor)),
              ),
            ),
          ),
          new Container(height: _monthNamePaddingTopBottom),
          new Flexible(
            child: new GridView.custom(
                gridDelegate: _kDayPickerGridDelegate,
                childrenDelegate: new SliverChildListDelegate(labels,
                    addRepaintBoundaries: false)),
          ),
        ],
      ),
    );
  }
}

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// The month picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showDatePicker].
  MonthPicker({
    Key key,
    @required this.selectedFirstDate,
    this.selectedLastDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
    this.selectableDayPredicate,
  })  : assert(selectedFirstDate != null),
        assert(onChanged != null),
        assert(!firstDate.isAfter(lastDate)),
        assert(!selectedFirstDate.isBefore(firstDate) &&
            (selectedLastDate == null || !selectedLastDate.isAfter(lastDate))),
        assert(selectedLastDate == null ||
            !selectedLastDate.isBefore(selectedFirstDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;

  /// Called when the user picks a month.
  final ValueChanged<List<DateTime>> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// Optional user supplied predicate function to customize selectable days.
  final SelectableDayPredicate selectableDayPredicate;

  @override
  _MonthPickerState createState() => new _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    int monthPage;
    if (widget.selectedLastDate == null) {
      monthPage = _monthDelta(widget.firstDate, widget.selectedFirstDate);
    } else {
      monthPage = _monthDelta(widget.firstDate, widget.selectedLastDate);
    }
    _dayPickerController = new PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage);
    _updateCurrentDate();

    // Setup the fade animation for chevrons
    _chevronOpacityController = new AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _chevronOpacityAnimation =
        new Tween<double>(begin: 1.0, end: 0.0).animate(new CurvedAnimation(
          parent: _chevronOpacityController,
          curve: Curves.easeInOut,
        ));
  }

  @override
  void didUpdateWidget(MonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLastDate == null) {
      final int monthPage =
      _monthDelta(widget.firstDate, widget.selectedFirstDate);
      _dayPickerController = new PageController(initialPage: monthPage);
      _handleMonthPageChanged(monthPage);
    } else if (oldWidget.selectedLastDate == null ||
        widget.selectedLastDate != oldWidget.selectedLastDate) {
      final int monthPage =
      _monthDelta(widget.firstDate, widget.selectedLastDate);
      _dayPickerController = new PageController(initialPage: monthPage);
      _handleMonthPageChanged(monthPage);
    }
  }

  MaterialLocalizations localizations;
  TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
  }

  DateTime _todayDate;
  DateTime _currentDisplayedMonthDate;
  Timer _timer;
  PageController _dayPickerController;
  AnimationController _chevronOpacityController;
  Animation<double> _chevronOpacityAnimation;

  void _updateCurrentDate() {
    _todayDate = new DateTime.now();
    final DateTime tomorrow =
    new DateTime(_todayDate.year, _todayDate.month, _todayDate.day + 1);
    Duration timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow +=
    const Duration(seconds: 1); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = new Timer(timeUntilTomorrow, () {
      setState(() {
        _updateCurrentDate();
      });
    });
  }

  static int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  /// Add months to a month truncated date.
  DateTime _addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return new DateTime(
        monthDate.year + monthsToAdd ~/ 12, monthDate.month + monthsToAdd % 12);
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = _addMonthsToMonthDate(widget.firstDate, index);
    return new DayPicker(
      key: new ValueKey<DateTime>(month),
      selectedFirstDate: widget.selectedFirstDate,
      selectedLastDate: widget.selectedLastDate,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_nextMonthDate), textDirection);
      _dayPickerController.nextPage(
          duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_previousMonthDate), textDirection);
      _dayPickerController.previousPage(
          duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate
        .isAfter(new DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate
        .isBefore(new DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  DateTime _previousMonthDate;
  DateTime _nextMonthDate;

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      _previousMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage - 1);
      _currentDisplayedMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage);
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      width: _kMonthPickerPortraitWidth,
      height: _kMaxDayPickerHeight,
      child: new Stack(
        children: <Widget>[
          // TODO All Calendar Container
          new Semantics(
            sortKey: _MonthPickerSortKey.calendar,
            child: new NotificationListener<ScrollStartNotification>(
              onNotification: (_) {
                _chevronOpacityController.forward();
                return false;
              },
              child: new NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  _chevronOpacityController.reverse();
                  return false;
                },
                child: new PageView.builder(
                  key: new ValueKey<DateTime>(widget.selectedFirstDate == null
                      ? widget.selectedFirstDate
                      : widget.selectedLastDate),
                  controller: _dayPickerController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _monthDelta(widget.firstDate, widget.lastDate) + 1,
                  itemBuilder: _buildItems,
                  onPageChanged: _handleMonthPageChanged,
                ),
              ),
            ),
          ),
          new PositionedDirectional(
            top: 0.0,
            start: 8.0,
            child: new Semantics(
              sortKey: _MonthPickerSortKey.previousMonth,
              child: new FadeTransition(
                opacity: _chevronOpacityAnimation,
                child: new IconButton(
                  icon: SvgPicture.asset('lib/assets/ic_arrow_left.svg'),
                  tooltip: _isDisplayingFirstMonth
                      ? null
                      : '${localizations.previousMonthTooltip} ${localizations.formatMonthYear(_previousMonthDate)}',
                  onPressed:
                  _isDisplayingFirstMonth ? null : _handlePreviousMonth,
                ),
              ),
            ),
          ),
          new PositionedDirectional(
            top: 0.0,
            end: 8.0,
            child: new Semantics(
              sortKey: _MonthPickerSortKey.nextMonth,
              child: new FadeTransition(
                opacity: _chevronOpacityAnimation,
                child: new IconButton(
                  icon:
                  SvgPicture.asset("lib/assets/ic_arrow_right.svg"),
                  tooltip: _isDisplayingLastMonth
                      ? null
                      : '${localizations.nextMonthTooltip} ${localizations.formatMonthYear(_nextMonthDate)}',
                  onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayPickerController?.dispose();
    super.dispose();
  }
}

// Defines semantic traversal order of the top-level widgets inside the month
// picker.
class _MonthPickerSortKey extends OrdinalSortKey {
  static const _MonthPickerSortKey previousMonth = _MonthPickerSortKey(1.0);
  static const _MonthPickerSortKey nextMonth = _MonthPickerSortKey(2.0);
  static const _MonthPickerSortKey calendar = _MonthPickerSortKey(3.0);

  const _MonthPickerSortKey(double order) : super(order);
}

/// A scrollable list of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class YearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of the dialog shown
  /// by [showDatePicker].
  YearPicker({
    Key key,
    @required this.selectedFirstDate,
    this.selectedLastDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate,
  })  : assert(selectedFirstDate != null),
        assert(onChanged != null),
        assert(!firstDate.isAfter(lastDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;

  /// Called when the user picks a year.
  final ValueChanged<List<DateTime>> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _YearPickerState createState() => new _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  static const double _itemExtent = 50.0;
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    int offset;
    if (widget.selectedLastDate != null) {
      offset = widget.lastDate.year - widget.selectedLastDate.year;
    } else {
      offset = widget.selectedFirstDate.year - widget.firstDate.year;
    }
    scrollController = new ScrollController(
      // Move the initial scroll position to the currently selected date's year.
      initialScrollOffset: offset * _itemExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.body1;
    return new ListView.builder(
      controller: scrollController,
      itemExtent: _itemExtent,
      itemCount: widget.lastDate.year - widget.firstDate.year + 1,
      itemBuilder: (BuildContext context, int index) {
        final int year = widget.firstDate.year + index;
        final bool isSelected = year == widget.selectedFirstDate.year ||
            (widget.selectedLastDate != null &&
                year == widget.selectedLastDate.year);
        final TextStyle itemStyle = isSelected
            ? themeData.textTheme.headline
            .copyWith(color: themeData.accentColor)
            : style;
        return new InkWell(
          key: new ValueKey<int>(year),
          onTap: () {
            List<DateTime> changes;
            if (widget.selectedLastDate == null) {
              DateTime newDate = new DateTime(year,
                  widget.selectedFirstDate.month, widget.selectedFirstDate.day);
              changes = [newDate, newDate];
            } else {
              changes = [
                new DateTime(year, widget.selectedFirstDate.month,
                    widget.selectedFirstDate.day),
                null
              ];
            }
            widget.onChanged(changes);
          },
          child: new Center(
            child: new Semantics(
              selected: isSelected,
              child: new Text(year.toString(), style: itemStyle),
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    Key key,
    this.initialFirstDate,
    this.initialLastDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.initialDatePickerMode,
    this.cb,
  }) : super(key: key);

  final DateTime initialFirstDate;
  final DateTime initialLastDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final SelectableDayPredicate selectableDayPredicate;
  final DatePickerMode initialDatePickerMode;
  final Function cb;

  @override
  _DatePickerDialogState createState() => new _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  @override
  void initState() {
    super.initState();
    _selectedFirstDate = widget.initialFirstDate;
    _selectedLastDate = widget.initialLastDate;
    _mode = widget.initialDatePickerMode;
  }

  bool _announcedInitialDate = false;

  MaterialLocalizations localizations;
  TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        localizations.formatFullDate(_selectedFirstDate),
        textDirection,
      );
      if (_selectedLastDate != null) {
        SemanticsService.announce(
          localizations.formatFullDate(_selectedLastDate),
          textDirection,
        );
      }
    }
  }

  DateTime _selectedFirstDate;
  DateTime _selectedLastDate;
  DatePickerMode _mode;
  final GlobalKey _pickerKey = new GlobalKey();

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
        break;
    }
  }

  void _handleModeChanged(DatePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      if (_mode == DatePickerMode.day) {
        SemanticsService.announce(
            localizations.formatMonthYear(_selectedFirstDate), textDirection);
        if (_selectedLastDate != null) {
          SemanticsService.announce(
              localizations.formatMonthYear(_selectedLastDate), textDirection);
        }
      } else {
        SemanticsService.announce(
            localizations.formatYear(_selectedFirstDate), textDirection);
        if (_selectedLastDate != null) {
          SemanticsService.announce(
              localizations.formatYear(_selectedLastDate), textDirection);
        }
      }
    });
  }

  void _handleYearChanged(List<DateTime> changes) {
    assert(changes != null && changes.length == 2);
    _vibrate();
    setState(() {
      _mode = DatePickerMode.day;
      _selectedFirstDate = changes[0];
      _selectedLastDate = changes[1];
    });
  }

  void _handleDayChanged(List<DateTime> changes) {
    developer.log('_handleDayChanged: $changes');
    assert(changes != null && changes.length == 2);
    _vibrate();
    setState(() {
      _selectedFirstDate = changes[0];
      _selectedLastDate = changes[1];
      DateTime firstDate = _selectedFirstDate;
      if (firstDate == null) {
        firstDate = _selectedLastDate;
      }
      DateTime lastDate = _selectedLastDate;
      if (lastDate == null) {
        lastDate = _selectedFirstDate;
      }
      developer.log('firstDate: $firstDate, lastDate: $lastDate');
      widget.cb(new DatePeriod(firstDate, lastDate));
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    List<DateTime> result = [];
    if (_selectedFirstDate != null) {
      result.add(_selectedFirstDate);
      if (_selectedLastDate != null) {
        result.add(_selectedLastDate);
      }
    }
    Navigator.pop(context, result);
  }

  Widget _buildPicker() {
    assert(_mode != null);
    switch (_mode) {
      case DatePickerMode.day:
        return new MonthPicker(
          key: _pickerKey,
          selectedFirstDate: _selectedFirstDate,
          selectedLastDate: _selectedLastDate,
          onChanged: _handleDayChanged,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case DatePickerMode.year:
        return new YearPicker(
          key: _pickerKey,
          selectedFirstDate: _selectedFirstDate,
          selectedLastDate: _selectedLastDate,
          onChanged: _handleYearChanged,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget picker = new Flexible(
      child: new SizedBox(
        height: _kMaxDayPickerHeight,
        child: _buildPicker(),
      ),
    );
    final Widget actions = new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: new Text(localizations.cancelButtonLabel),
            onPressed: _handleCancel,
          ),
          new FlatButton(
            child: new Text(localizations.okButtonLabel),
            onPressed: _handleOk,
          ),
        ],
      ),
    );
    final Dialog dialog = new Dialog(child: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          assert(orientation != null);
          Widget header;
          if (_isHeaderShow) {
            header = new _DatePickerHeader(
              selectedFirstDate: _selectedFirstDate,
              selectedLastDate: _selectedLastDate,
              mode: _mode,
              onModeChanged: _handleModeChanged,
              orientation: orientation,
            );
          } else {
            header = new Container(width: 0.0, height: 0.0);
          }
          switch (orientation) {
            case Orientation.portrait:
              return new SizedBox(
                width: _kMonthPickerPortraitWidth,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _calendarBackgroundColor),
                      child: new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          new Container(height: _monthNamePaddingTopBottom),
                          picker,
                          new Container(height: _monthNamePaddingTopBottom),
                          // actions, - Not need Acton btn in this flow
                        ],
                      ),
                    ),
                  ],
                ),
              );
            case Orientation.landscape:
              return new SizedBox(
                height: _kDatePickerLandscapeHeight,
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    new Flexible(
                      child: new Container(
                        width: _kMonthPickerLandscapeWidth,
                        color: theme.dialogBackgroundColor,
                        child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[picker, actions],
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
          return null;
        }));

    return new Theme(
      data: theme.copyWith(
        dialogBackgroundColor: Colors.transparent,
      ),
      child: dialog,
    );
  }
}

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker].
typedef bool SelectableDayPredicate(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// An optional [initialDatePickerMode] argument can be used to display the
/// date picker initially in the year or month+day picker mode. It defaults
/// to month+day, and must not be null.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// (RTL or LTR) for the date picker. It defaults to the ambient text direction
/// provided by [Directionality]. If both [locale] and [textDirection] are not
/// null, [textDirection] overrides the direction chosen for the [locale].
///
/// The `context` argument is passed to [showDialog], the documentation for
/// which discusses how it is used.
///
/// See also:
///
///  * [showTimePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
Future<List<DateTime>> showDatePicker({
  @required BuildContext context,
  @required DateTime initialFirstDate,
  @required DateTime initialLastDate,
  @required DateTime firstDate,
  @required DateTime lastDate,
  SelectableDayPredicate selectableDayPredicate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  Locale locale,
  TextDirection textDirection,
}) async {
  assert(!initialFirstDate.isBefore(firstDate),
  'initialDate must be on or after firstDate');
  assert(!initialLastDate.isAfter(lastDate),
  'initialDate must be on or before lastDate');
  assert(!initialFirstDate.isAfter(initialLastDate),
  'initialFirstDate must be on or before initialLastDate');
  assert(
  !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(
  selectableDayPredicate == null ||
      selectableDayPredicate(initialFirstDate) ||
      selectableDayPredicate(initialLastDate),
  'Provided initialDate must satisfy provided selectableDayPredicate');
  assert(
  initialDatePickerMode != null, 'initialDatePickerMode must not be null');

  Widget child = new _DatePickerDialog(
    initialFirstDate: initialFirstDate,
    initialLastDate: initialLastDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: selectableDayPredicate,
    initialDatePickerMode: initialDatePickerMode,
  );

  if (textDirection != null) {
    child = new Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  if (locale != null) {
    child = new Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return await showDialog<List<DateTime>>(
    context: context,
    builder: (BuildContext context) => child,
  );
}

Widget getDatePicker(
    {@required BuildContext context,
      @required DateTime initialFirstDate,
      @required DateTime initialLastDate,
      @required DateTime firstDate,
      @required DateTime lastDate,
      SelectableDayPredicate selectableDayPredicate,
      DatePickerMode initialDatePickerMode = DatePickerMode.day,
      Locale locale,
      TextDirection textDirection,
      Function cb}) {
  assert(!initialFirstDate.isBefore(firstDate),
  'initialDate must be on or after firstDate');
  assert(!initialLastDate.isAfter(lastDate),
  'initialDate must be on or before lastDate');
  assert(!initialFirstDate.isAfter(initialLastDate),
  'initialFirstDate must be on or before initialLastDate');
  assert(
  !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(
  selectableDayPredicate == null ||
      selectableDayPredicate(initialFirstDate) ||
      selectableDayPredicate(initialLastDate),
  'Provided initialDate must satisfy provided selectableDayPredicate');
  assert(
  initialDatePickerMode != null, 'initialDatePickerMode must not be null');

  Widget child = new _DatePickerDialog(
      initialFirstDate: initialFirstDate,
      initialLastDate: initialLastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
      initialDatePickerMode: initialDatePickerMode,
      cb: cb);

  if (textDirection != null) {
    child = new Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  if (locale != null) {
    child = new Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return child;
}

class RainbowGradient extends LinearGradient {
  RainbowGradient({
    @required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.topRight,
  }) : super(
    begin: begin,
    end: end,
    colors: _buildColors(colors),
    stops: _buildStops(colors),
  );

  static List<Color> _buildColors(List<Color> colors) {
    return colors.fold<List<Color>>(<Color>[],
            (List<Color> list, Color color) => list..addAll(<Color>[color, color]));
  }

  static List<double> _buildStops(List<Color> colors) {
    final List<double> stops = <double>[0.0];

    for (int i = 1, len = colors.length; i < len; i++) {
      stops.add(i / colors.length);
      stops.add(i / colors.length);
    }

    return stops..add(1.0);
  }
}
