import 'package:shared_preferences/shared_preferences.dart';

class Helper{

  Future<bool> setLogStatus(bool logStatus) async{
    SharedPreferences saveLogStatus = await SharedPreferences.getInstance();
    return await saveLogStatus.setBool("log", logStatus);
  }

  Future<bool> setName(String name) async{
    SharedPreferences saveName = await SharedPreferences.getInstance();
    return await saveName.setString("name", name);

  }

  Future<bool> setEmail(String email) async{
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return await saveEmail.setString("email", email);
  }

  Future<bool> setSvg(String svg) async{
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return await saveEmail.setString("svg", svg);
  }

  Future<bool?> getLogStatus() async{
    SharedPreferences saveLogStatus = await SharedPreferences.getInstance();
    return saveLogStatus.getBool("log");
  }

  Future<String?> getName() async{
    SharedPreferences saveName = await SharedPreferences.getInstance();
    return saveName.getString("name");

  }

  Future<String?> getEmail() async{
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return saveEmail.getString("email");
  }

  Future<String?> getSvg() async{
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return saveEmail.getString("svg");
  }

}