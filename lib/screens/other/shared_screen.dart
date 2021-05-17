import 'package:flutter/material.dart';
import 'package:simplechat/widgets/appbar_widget.dart';

class SharedScreen extends StatefulWidget {
  final String type;
  final String data;

  const SharedScreen({Key key, this.type, this.data}) : super(key: key);

  @override
  _SharedScreenState createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainBarWidget(
        titleString: 'Shared Data',
      ),
    );
  }
}
