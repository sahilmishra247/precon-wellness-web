import '../models/client.dart';
import '../models/note.dart';
import '../models/progress_entry.dart';
import '../models/exercise.dart';
import '../models/food_item.dart';
import '../models/appointment.dart';

class AppData {
  static final List<Appointment> appointments = [];
  static final List<Client> clients = [
    Client(
      fullName: "John Smith",
      age: 28,
      gender: "Male",
      height: 175,
      weight: 82,
      goal: "Weight Loss",
      phoneNumber: "9876543210",
      email: "john@gmail.com",
    ),

    Client(
      fullName: "Sarah Johnson",
      age: 32,
      gender: "Female",
      height: 165,
      weight: 68,
      goal: "Fitness",
      phoneNumber: "9876543211",
      email: "sarah@gmail.com",
    ),

    Client(
      fullName: "Michael Lee",
      age: 40,
      gender: "Male",
      height: 180,
      weight: 90,
      goal: "Muscle Gain",
      phoneNumber: "9876543212",
      email: "michael@gmail.com",
    ),
  ];

  static final List<Note> notes = [];

  static final List<ProgressEntry> progressEntries = [];

  static final List<Exercise> exercises = [];

  static final List<FoodItem> breakfastItems = [];
  static final List<FoodItem> lunchItems = [];
  static final List<FoodItem> dinnerItems = [];
  static final List<FoodItem> snacksItems = [];
}
