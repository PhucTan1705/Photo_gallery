import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_gallery/auth/auth_error.dart';
import 'package:photo_gallery/bloc/app_event.dart';
import 'package:photo_gallery/bloc/app_state.dart';
import '../utils/upload_image.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc()
      : super(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        ) {
    on<AppEventGoToRegistration>(
      (event, emit) {
        emit(
          const AppStateIsInRegistrationView(
            isLoading: false,
          ),
        );
      },
    );
    on<AppEventLogIn>(
      (event, emit) async {
        emit(
          const AppStateLoggedOut(
            isLoading: true,
          ),
        );
        //log user in
        try {
          final email = event.email;
          final password = event.password;
          final userCredeential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          //get user images
          final user = userCredeential.user!;
          final images = await _getImages(user.uid);
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: user,
              images: images,
            ),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateLoggedOut(
              isLoading: false,
              authError: AuthError.from(e),
            ),
          );
        }
      },
    );
    on<AppEventGoToLogin>(
      (event, emit) {
        emit(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        );
      },
    );
    on<AppEventRegister>(
      (event, emit) async {
        //start loading
        emit(
          const AppStateIsInRegistrationView(isLoading: true),
        );
        final email = event.email;
        final password = event.password;
        try {
          //create user
          final credentials =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: credentials.user!,
              images: const [],
            ),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateIsInRegistrationView(
              isLoading: false,
              authError: AuthError.from(e),
            ),
          );
        }
      },
    );

    on<AppEventInitialize>(
      (event, emit) async {
        //get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          emit(
            const AppStateLoggedOut(
              isLoading: false,
            ),
          );
        } else {
          //grap the user uploade images
          final images = await _getImages(user.uid);
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: user,
              images: images,
            ),
          );
        }
      },
    );
    // log out event
    on<AppEventLogOut>(
      (event, emit) async {
        emit(
          const AppStateLoggedOut(
            isLoading: true,
          ),
        );
        //log user out
        await FirebaseAuth.instance.signOut();
        //log out
        emit(
          const AppStateLoggedOut(isLoading: false),
        );
      },
    );
    //handle accout deletion
    on<AppEventDeleteAccount>(
      (event, emit) async {
        final user = FirebaseAuth.instance.currentUser;
        //log user out if curent user empty
        if (user == null) {
          emit(
            const AppStateLoggedOut(isLoading: false),
          );
          return;
        }
        //start loading
        emit(
          AppStateLoggedIn(
            isLoading: true,
            user: user,
            images: state.images ?? [],
          ),
        );
        //delete the use folder
        try {
          //delete user folder
          final folder = await FirebaseStorage.instance.ref(user.uid).listAll();
          for (final item in folder.items) {
            await item.delete().catchError((_) {}); //add eror handle later
          }
          //delete the folder itself
          await FirebaseStorage.instance
              .ref(user.uid)
              .delete()
              .catchError((_) {});
          //delete the user
          await user.delete();
          //log user out
          await FirebaseAuth.instance.signOut();
          //log out
          emit(
            const AppStateLoggedOut(isLoading: false),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateLoggedIn(
              isLoading: true,
              user: user,
              images: state.images ?? [],
              authError: AuthError.from(e),
            ),
          );
        } on FirebaseException {
          //we might not be able to delte the folder
          emit(
            const AppStateLoggedOut(
              isLoading: false,
            ),
          );
        }
      },
    );

    //

    on<AppEventUploadImage>(
      (event, emit) async {
        final user = state.user;
        //log user out if we don't have an actual user in app state
        if (user == null) {
          emit(
            const AppStateLoggedOut(
              isLoading: false,
            ),
          );
          return;
        }
        //start the loading process
        emit(
          AppStateLoggedIn(
            isLoading: true,
            user: user,
            images: state.images ?? [],
          ),
        );
        //upload file
        final file = File(event.filePathToUpload);
        await uploadImage(
          file: file,
          useId: user.uid,
        );
        //after upload is complete, grap the latest file references
        final images = await _getImages(user.uid);
        //emit the new images and turn off loading
        emit(
          AppStateLoggedIn(
            isLoading: false,
            user: user,
            images: images,
          ),
        );
      },
    );
  }

  Future<Iterable<Reference>> _getImages(String userId) =>
      FirebaseStorage.instance
          .ref(userId)
          .list()
          .then((listResult) => listResult.items);
}
