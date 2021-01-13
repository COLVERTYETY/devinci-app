//DEPENDENCIES
import 'dart:convert';
import 'dart:io';
import 'package:sembast/sembast.dart';
import 'package:devinci/libraries/devinci/extra/functions.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:devinci/extra/globals.dart' as globals;
import 'package:sembast/utils/value_utils.dart';

//DATA
int currentSemester = 0;
bool show = false;
bool first = true;
final RefreshController refreshController =
    RefreshController(initialRefresh: false);
final ScrollController scrollController = ScrollController(
  initialScrollOffset:
      globals.isConnected ? 42 : 0, //pour cacher le choix de l'année
  keepScrollOffset: true,
);
String currentYear = '';
bool changed = false;
int index = 0;

//FUNCTIONS
void changeCurrentSemester(int sem) {
  setState(() {
    currentSemester = sem;
    if (!changed) changed = true;
  });
}

Future<void> getData({bool force = false}) async {
  if (!force) {
    var tmpNotes =
        await globals.store.record('notes').get(globals.db) as List<dynamic>;
    globals.user.notes = cloneList(tmpNotes);
  }
  if (force || globals.user.notes.isEmpty) {
    if (globals.isConnected) {
      try {
        await globals.user.getNotesList();
        currentYear = globals.user.notesList[index][0];

        try {
          await globals.user.getNotes(globals.user.notesList[index][1], index);
        } catch (exception, stacktrace) {
          catcher(exception, stacktrace);
        }
      } catch (exception, stacktrace) {
        catcher(exception, stacktrace);
      }
    }
  }
  try {
    if (globals.user.notes.isNotEmpty) {
      if (!globals.user.notes[index]['s'][1].isEmpty && !changed) {
        currentSemester = 1;
      }
    }

    setState(() {
      show = true;
    });
  } catch (e) {
    l(e);
  }
  if (!globals.user.notesFetched && globals.isConnected) {
    globals.isLoading.setState(1, true);
  }

  return;
}

void onRefresh() async {
  if (!globals.noteLocked) {
    globals.noteLocked = true;
    try {
      await globals.user.getNotesList();
      currentYear = globals.user.notesList[index][0];
      try {
        await globals.user.getNotes(globals.user.notesList[index][1], index);
      } catch (exception, stacktrace) {
        catcher(exception, stacktrace);
      }
    } catch (exception, stacktrace) {
      catcher(exception, stacktrace);
    }
    globals.noteLocked = false;
  }

  setState(() {
    if (!globals.user.notes[index]['s'][1].isEmpty && !changed) {
      currentSemester = 1;
    }
    refreshController.refreshCompleted();
  });
}

void catcher(var exception, StackTrace stacktrace) async {
  if (globals.isConnected) {
    var client = HttpClient();
    var req = await client.getUrl(
      Uri.parse('https://www.leonard-de-vinci.net/?my=notes'),
    );
    req.followRedirects = false;
    req.cookies.addAll([
      Cookie('alv', globals.user.tokens['alv']),
      Cookie('SimpleSAML', globals.user.tokens['SimpleSAML']),
      Cookie('uids', globals.user.tokens['uids']),
      Cookie('SimpleSAMLAuthToken', globals.user.tokens['SimpleSAMLAuthToken']),
    ]);
    var res = await req.close();
    globals.feedbackNotes = await res.transform(utf8.decoder).join();

    await reportError(
        'notes.dart | _NotesPageState | runBeforeBuild() | user.getNotes() => $exception',
        stacktrace);
  }
}

void runBeforeBuild() async {
  if (!globals.user.notesFetched) {
    await getData();
  } else {
    setState(() {
      if (!globals.user.notes[index]['s'][1].isEmpty && !changed) {
        currentSemester = 1;
      }
      show = true;
    });
  }
}

BuildContext getContext() {
  if (globals.notesPageKey.currentState != null) {
    return globals.notesPageKey.currentState.context;
  } else {
    return globals.currentContext;
  }
}

void setState(void Function() fun, {bool condition = true}) {
  if (globals.notesPageKey.currentState != null) {
    if (globals.notesPageKey.currentState.mounted && condition) {
      // ignore: invalid_use_of_protected_member
      globals.notesPageKey.currentState.setState(fun);
    }
  }
}
