import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:schedule/utils/util.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);
  static const routeName = 'SplashScreen';

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Positioned(
              top: 50,
              child: Column(
                children: [
                  Image.asset("assets/images/logo.png"),
                  SvgPicture.asset("assets/icons/name.svg"),
                ],
              )),
          Positioned(
              bottom: 50,
              right: 30,
              left: 30,
              child: Column(
                children: [
                  MaterialButton(
                    onPressed: clientLogin,
                    color: theme.secondaryHeaderColor,
                    height: 60,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            "assets/icons/gmail_login.svg",
                            height: 50,
                            width: 50,
                          ),
                          Expanded(
                              child: Text(
                            "Sign in with Google",
                            textAlign: TextAlign.center,
                            style: Fonts.display4(),
                          ))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Sign in with Google is mandatory to create a calendar invite using Simply Schedule",
                    textAlign: TextAlign.center,
                    style: Fonts.body2(),
                  )
                ],
              )),
        ],
      ),
    );
  }
}
