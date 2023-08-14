import 'package:flutter/material.dart' show BuildContext;
import 'package:photo_gallery/dialogs/generic_dialog.dart';

Future<bool> showDeleteAccountDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete account',
    content:
        'Are you sure want to delete your account? You cannot undo this operation!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete account': true,
    },
  ).then((value) => value ?? false);
}
