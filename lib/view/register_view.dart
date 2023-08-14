import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:photo_gallery/bloc/app_bloc.dart';
import 'package:photo_gallery/bloc/app_event.dart';
import 'package:photo_gallery/extensions/if_debuggingg.dart';

class RegisterView extends HookWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(
      text: 'nanaxanime4@gmail.com'.ifDebugging,
    );

    final passwordController = useTextEditingController(
      text: 'Otoxmaho1@'.ifDebugging,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Enter your email here...',
              ),
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.dark,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: 'Enter your password here...',
              ),
              keyboardAppearance: Brightness.dark,
              obscureText: true,
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final password = passwordController.text;
                context.read<AppBloc>().add(
                      AppEventRegister(
                        email: email,
                        password: password,
                      ),
                    );
              },
              child: const Text(
                'Register',
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppBloc>().add(
                      const AppEventGoToLogin(),
                    );
              },
              child: const Text(
                'Already registered? Login here!',
              ),
            )
          ],
        ),
      ),
    );
  }
}
