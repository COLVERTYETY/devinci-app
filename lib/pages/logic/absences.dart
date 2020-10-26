//DEPENDENCIES
import 'dart:convert';
import 'dart:io';

import 'package:devinci/libraries/devinci/extra/functions.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sembast/sembast.dart';
import 'package:devinci/extra/globals.dart' as globals;
import 'package:sembast/utils/value_utils.dart';

//DATA
bool show = false;
RefreshController refreshController = RefreshController(initialRefresh: false);

//FUNCTIONS

Future<void> getData({bool force = false}) async {
  if (!force) {
    var tmpAbsences = await globals.store.record('absences').get(globals.db);
    if (!globals.isConnected) {
      globals.user.absences = cloneMap(tmpAbsences);
    } else {
      if (tmpAbsences != null) globals.user.absences = cloneMap(tmpAbsences);
      globals.isLoading.setState(2, true);
    }
  } else {
    try {
      await globals.user.getAbsences();
    } catch (exception, stacktrace) {
      var client = HttpClient();
      var req = await client.getUrl(
        Uri.parse('https://www.leonard-de-vinci.net/?my=abs'),
      );
      req.followRedirects = false;
      req.cookies.addAll([
        Cookie('alv', globals.user.tokens['alv']),
        Cookie('SimpleSAML', globals.user.tokens['SimpleSAML']),
        Cookie('uids', globals.user.tokens['uids']),
        Cookie(
            'SimpleSAMLAuthToken', globals.user.tokens['SimpleSAMLAuthToken']),
      ]);
      var res = await req.close();
      globals.feedbackNotes = await res.transform(utf8.decoder).join();

      await reportError(
          'absences.dart | _AbsencesPageState | runBeforeBuild() | user.getAbsences() => $exception',
          stacktrace);
    }
  }

  if (globals.absencesPageKey.currentState.mounted) {
    globals.absencesPageKey.currentState.setState(() {
      show = true;
    });
  }

  return;
}

void runBeforeBuild() async {
  if (globals.user.absences != null) {
    if (!globals.user.absences["done"]) {
      await getData();
    }
  }

  if (globals.absencesPageKey.currentState.mounted && !show) {
    globals.absencesPageKey.currentState.setState(() {
      show = true;
    });
  }
}

void onRefresh() async {
  await getData(force: true);
  if (globals.absencesPageKey.currentState.mounted) {
    globals.absencesPageKey.currentState.setState(() {
      show = true;
      refreshController.refreshCompleted();
    });
  }
}
