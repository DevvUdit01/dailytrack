import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dailytrack/controllers/task_controller.dart';
import 'package:dailytrack/core/model/task.dart';
import 'package:dailytrack/pages/add_task_bar.dart';
import 'package:dailytrack/services/theme_service.dart';
import 'package:dailytrack/utils/button.dart';
import 'package:dailytrack/utils/task_tile.dart';
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification_service.dart';
import '../utils/Themes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskController _taskController = Get.put(TaskController());
  DateTime _selectedDate = DateTime.now();
  var notifyHelper = NotifyHelper();

  late String _local;
  final GetStorage _storage = GetStorage();

  // List to keep track of scheduled notification IDs
  List<int> scheduledNotificationIds = [];

  @override
  void initState() {
    super.initState();
    notifyHelper.initializeNotification();
    _taskController.getTasks();  // Ensure tasks are loaded when the page starts
    _local = "Some default value"; // Initialize the _local variable safely
    _loadScheduledNotifications();
  }

    // Load scheduled notification IDs from GetStorage
  void _loadScheduledNotifications() {
    scheduledNotificationIds = _storage.read<List>('scheduledNotificationIds')?.cast<int>() ?? [];
  }

  // Save scheduled notification IDs to GetStorage
  Future<void> _saveScheduledNotifications() async {
    await _storage.write('scheduledNotificationIds', scheduledNotificationIds);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _appBar(),
      body: Column(
        children: [
          _addTaskBar(),
          _addDateBar(),
          SizedBox(height: 20),
          _showTasks(),
        ],
      ),
    );
  }

_showTasks() {
  return Expanded(
    child: Obx(() {
      return ListView.builder(
        itemCount: _taskController.taskList.length,
        itemBuilder: (_, index) {
          Task task = _taskController.taskList[index];

          // Parse the task date
          DateTime taskDate;
          try {
            taskDate = _parseDate(task.date!);
          } catch (e) {
            print("Error parsing task date: ${task.date}");
            return Container(); // Skip this task if the date is invalid
          }

          String taskDateFormatted = DateFormat.yMd().format(taskDate);
          String selectedDateFormatted = DateFormat.yMd().format(_selectedDate);

          // Handle task based on repeat type
          if (task.repeat == "None" && taskDateFormatted == selectedDateFormatted) {
            _scheduleNotificationForTask(task, isOneTime: true); // Schedule one-time notification
            return _buildTaskRow(task, index);
          } else if (task.repeat == "Daily") {
            _scheduleNotificationForTask(task); // Schedule daily notification
            return _buildTaskRow(task, index);
          } else if (task.repeat == "Weekly" && _isSameDayOfWeek(taskDate, _selectedDate)) {
            _scheduleNotificationForTask(task, weekly: true); // Schedule weekly notification
            return _buildTaskRow(task, index);
          } else if (task.repeat == "Monthly" && _isSameDayOfMonth(taskDate, _selectedDate)) {
            _scheduleNotificationForTask(task, monthly: true); // Schedule monthly notification
            return _buildTaskRow(task, index);
          } else {
            return Container();
          }
        },
      );
    }),
  );
}

DateTime _parseDate(String dateString) {
  try {
    // Try parsing the date in the format "M/d/yyyy" (e.g., "2/13/2025")
    return DateFormat("M/d/yyyy").parse(dateString);
  } catch (e) {
    // If parsing fails, try parsing in the default format (e.g., "yyyy-MM-dd")
    return DateTime.parse(dateString);
  }
}

void _scheduleNotificationForTask(Task task, {bool weekly = false, bool monthly = false, bool isOneTime = false}) async {
  // Get hour and minute from task start time
  String myTime = _getFormattedTime(task.startTime.toString());
  int hour = int.parse(myTime.split(":")[0]);
  int minute = int.parse(myTime.split(":")[1]);

  // Check if the task notification is already scheduled
  if (scheduledNotificationIds.contains(task.id)) {
    print("Notification for task '${task.title}' is already scheduled.");
    return; // Skip scheduling if it's already scheduled
  }

  // Request permission for exact alarm scheduling
  await requestExactAlarmPermission();

  if (isOneTime) {
    // For "None", schedule one-time notification
    await notifyHelper.scheduledNotification(hour, minute, task, oneTime: true);
  } else if (weekly) {
    // For "Weekly", schedule notification to repeat every 7 days
    await notifyHelper.scheduledNotification(hour, minute, task, weekly: true);
  } else if (monthly) {
    // For "Monthly", schedule notification to repeat every month
    await notifyHelper.scheduledNotification(hour, minute, task, monthly: true);
  } else {
    // For "Daily", schedule notification to repeat every day
    await notifyHelper.scheduledNotification(hour, minute, task);
  }

  // Add task notification ID to the list and save it
  scheduledNotificationIds.add(task.id!);
  await _saveScheduledNotifications();
  print("Scheduled notification for task '${task.title}' at $hour:$minute.");
}

  // Helper method to create task row with animation
  Widget _buildTaskRow(Task task, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      child: SlideAnimation(
        child: FadeInAnimation(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showBottomSheet(context, task);
                },
                child: TaskTile(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: task.isCompleted == 1
            ? MediaQuery.of(context).size.height * 0.24
            : MediaQuery.of(context).size.height * 0.32,
        color: Get.isDarkMode ? darkgreyClr : Colors.white,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            Spacer(),
            task.isCompleted == 1
                ? Container()
                : _bottomSheetButton(
                    label: "Task completed",
                    onTap: () {
                      _taskController.markTaskCompleted(task.id!);
                      Get.back();
                    },
                    clr: primaryClr,
                    context: context,
                  ),
            _bottomSheetButton(
              label: "Delete Task",
              onTap: () {
                // Cancel the notification when deleting the task
                _cancelNotificationForTask(task);
                _taskController.delete(task);
                Get.back();
              },
              clr: Colors.red[300]!,
              context: context,
            ),
            SizedBox(height: 20),
            _bottomSheetButton(
              label: "Close",
              onTap: () {
                Get.back();
              },
              isclose: true,
              clr: Colors.red[300]!,
              context: context,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  _bottomSheetButton({
    required String label,
    required Function() onTap,
    required Color clr,
    bool isclose = false,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 55,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: isclose == true
                  ? Get.isDarkMode
                      ? Colors.grey[600]!
                      : Colors.grey[300]!
                  : clr,
            ),
            borderRadius: BorderRadius.circular(20),
            color: isclose == true ? Colors.transparent : clr,
          ),
          child: Center(
            child: Text(
              label,
              style: isclose ? titleStyle : titleStyle.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: DatePicker(
        DateTime.now(),
        height: 100,
        width: 80,
        initialSelectedDate: DateTime.now(),
        selectionColor: primaryClr,
        selectedTextColor: Colors.white,
        dateTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
        dayTextStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
        monthTextStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
        onDateChange: (selectedDate) {
          setState(() {
            _selectedDate = selectedDate;
          });
        },
      ),
    );
  }

  _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      leading: GestureDetector(
        onTap: () {
          ThemeService().switchTheme();
          notifyHelper.displayNotification(
            title: "theme changed",
            body: Get.isDarkMode ? "Activated light theme" : "Activated dark theme ",
          );
          notifyHelper.checkPendingNotifications();
          
        },
        child: Icon(
          Get.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage("assets/image.jpg"),
          ),
        ),
      ],
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: subHeadingStyle,
                ),
                Text(
                  'Today',
                  style: headingStyle,
                ),
              ],
            ),
          ),
          MyButton(
            label: "+ Add Task",
            onTap: () async {
              await Get.to(AddTaskPage());
              _taskController.getTasks();
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      print("Exact alarm permission granted.");
    } else {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isGranted) {
        print("Exact alarm permission granted.");
      } else {
        print("Exact alarm permission denied.");
      }
    }
  }

  // Helper method to parse the task start time safely
  String _getFormattedTime(String startTime) {
    try {
      DateTime parsedTime = DateFormat.jm().parse(startTime);
      return DateFormat("HH:mm").format(parsedTime);
    } catch (e) {
      print("Error parsing task time: $startTime");
      return "00:00"; // Return default value if parsing fails
    }
  }

  // Method to cancel notifications when a task is deleted
 void _cancelNotificationForTask(Task task) async {
  if (scheduledNotificationIds.contains(task.id)) {
    AwesomeNotifications().cancel(task.id!);  // Cancel the notification using the task ID
    scheduledNotificationIds.remove(task.id); // Remove from the list
    await _saveScheduledNotifications(); // Save the updated list
    print("Notification for task '${task.title}' canceled.");
  }
}

bool _isSameDayOfWeek(DateTime date1, DateTime date2) {
  return date1.weekday == date2.weekday; // Compare the day of the week (Monday = 1, Sunday = 7)
}

bool _isSameDayOfMonth(DateTime date1, DateTime date2) {
  return date1.day == date2.day; // Compare the day of the month
}
}
