import 'package:dailytrack/controllers/task_controller.dart';
import 'package:dailytrack/core/model/task.dart';
import 'package:dailytrack/utils/button.dart';
import 'package:dailytrack/utils/input_field.dart';
import 'package:dailytrack/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _startTime = DateFormat("hh:mm a").format(DateTime.now()).toString();
  String _endTime = "10:00 PM";
  int _selectedRemind = 5;
  List <int> remindList = [5,10,15,20];
  String _selectedRepeat = "None";
  List <String> repeatList = ["None","Daily","Weekly","Monthly"];
  int _selectedColor = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: Container(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              "Add Task",
              style: headingStyle,
              ),
              MyInputField(title: "Title", hint: "Enter your title", controller: _titleController,),
              MyInputField(title: "Note", hint: "Enter your note", controller: _noteController,),
              MyInputField(title: "Date", hint: DateFormat.yMMMd().format(_selectedDate), 
              widget: IconButton(
                onPressed: _getDateFromUser,
                icon: Icon(Icons.calendar_today_outlined, color: Colors.grey,)
                ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: MyInputField(
                        title: "Start Time", 
                        hint: _startTime,
                        widget: IconButton(
                          onPressed: (){
                            _getTimeFromUser(isStartTime:true);
                          }, 
                          icon: Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey,
                          )
                          ),
                        )
                      ),

                      SizedBox(width: 12,),

                      Expanded(
                      child: MyInputField(
                        title: "End Time", 
                        hint: _endTime,
                        widget: IconButton(
                          onPressed: (){
                            _getTimeFromUser(isStartTime:false);
                          }, 
                          icon: Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey,
                          )
                          ),
                        )
                      )
                  ],
                ),

            MyInputField(title: "Remind", hint: "$_selectedRemind minutes early",
             widget: DropdownButton(
              icon: Icon(Icons.keyboard_arrow_down, color:Colors.grey),
              elevation: 4,
              iconSize: 32,
              style: subTitleStyle,
              underline: Container(height: 0,),
              items: remindList.map<DropdownMenuItem<String>>((int value){
                return DropdownMenuItem<String>(
                  value: value.toString(),
                  child: Text(value.toString()),
                  );
              }).toList(), 
              onChanged: (String? val){
                setState(() {
                  _selectedRemind = int.parse(val!);
                });
              }
              ),
            ),


            MyInputField(title: "Repeat", hint: "$_selectedRepeat",
             widget: DropdownButton(
              icon: Icon(Icons.keyboard_arrow_down, color:Colors.grey),
              elevation: 4,
              iconSize: 32,
              style: subTitleStyle,
              underline: Container(height: 0,),
              items: repeatList.map<DropdownMenuItem<String>>((String value){
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                  );
              }).toList(), 
              onChanged: (String? val){
                setState(() {
                  _selectedRepeat = val!;
                });
              }
              ),
            ),

            SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _colorPalette(),
                MyButton(label: "Create Task", onTap: _validateDate)
              ],
            )
            ],
          ),
        ),
      ),
    );
  }
 

    _validateDate(){
      if(_titleController.text.isNotEmpty && _noteController.text.isNotEmpty){
        _addTaskToDb();
        Get.back();
      }
      else if (_startTime.isEmpty || _endTime.isEmpty) {
  Get.snackbar("Time Required", "Please select a valid start and end time.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: pinkClr,
      icon: Icon(Icons.warning_amber_rounded));
}

      else if(_titleController.text.isNotEmpty || _noteController.text.isNotEmpty){
        Get.snackbar("Required", "All fields are required !",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: pinkClr,
        icon: Icon(Icons.warning_amber_rounded)
        );
      }
    }


    _addTaskToDb()async{
      int value = await _taskController.addTask(
      task :Task(
        note: _noteController.text,
        title: _titleController.text,
        date: DateFormat.yMd().format(_selectedDate),
        startTime: _startTime,
        endTime: _endTime,
        remind: _selectedRemind,
        repeat: _selectedRepeat,
        color: _selectedColor,
        isCompleted: 0,
      )
     );
     print("my id is "+"$value");
    }
    
    _colorPalette(){
      return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Color",
                      style: titleStyle
                    ),
                    SizedBox(height: 8,),
                    Wrap(
                      children: List<Widget>.generate(
                        3,(int index){
                          return GestureDetector(
                            onTap: (){
                              setState(() {
                                _selectedColor = index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: index==0?primaryClr:index==1 ?pinkClr:yellowClr,
                                child: _selectedColor == index?Icon(
                                  Icons.done,
                                  color: Colors.white,
                                  size: 16,
                                ):Container()
                              ),
                            ),
                          );
                        }
                      ),
                    )
                  ],
                );
    }

    _getTimeFromUser({required bool isStartTime}) async {
  var _pickedTime = await _showTimePicker();
  if (_pickedTime == null) {
    print("Time canceled");
  } else {
    final formattedTime = _pickedTime.format(context);
    setState(() {
      if (isStartTime) {
        _startTime = formattedTime;
      } else {
        _endTime = formattedTime;
      }
    });
  }
}

  _showTimePicker(){
    return showTimePicker(
      context: context, 
      initialTime: TimeOfDay(
        hour: int.parse(_startTime.split(':')[0]), 
        minute: int.parse(_startTime.split(':')[1].split(' ')[0]),
        )
      );
  }


  _getDateFromUser()async{
    DateTime? _pickerDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime(2125)
    );

    if(_pickerDate != null){
      setState(() {
        _selectedDate = _pickerDate;
        print(_selectedDate);
      });
    }else{
      print('its null or something is wroing ');
    }
  }

   _appBar(BuildContext context){
    return AppBar(
        elevation: 0,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage("assets/image.jpg"),
          )
        ],
      );
  }
}