# date_range_picker

Flutter date range pickers use a dialog window to select a range of date on mobile.

## Demo

![](demo.gif)

## Getting Started

### Installation

Add to `pubspec.yaml` in `dependencies` 

```
  date_range_picker:
    git:
      url: git://github.com/anicdh/date_range_picker.git
```

### Usage
```
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;
...
new MaterialButton(
    color: Colors.deepOrangeAccent,
    onPressed: () async {
      final List<DateTime> picked = await DateRagePicker.showDatePicker(
          context: context,
          initialFirstDate: new DateTime.now(),
          initialLastDate: (new DateTime.now()).add(new Duration(days: 7)),
          firstDate: new DateTime(2015),
          lastDate: new DateTime(2020)
      );
      if (picked != null && picked.length == 2) {
          print(picked);
      }
    },
    child: new Text("Pick date range")
)
```
