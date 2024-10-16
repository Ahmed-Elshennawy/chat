// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:chat/widgets/user_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  var _enteredUsername = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  var isLogin = true;
  File? _selectedImage;
  var isUploading = false;
  void submit() async {
    final valid = _formkey.currentState!.validate();
    if (!valid || (!isLogin && _selectedImage == null)) {
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });
      if (isLogin) {
        final UserCredential userCondential =
            await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        final UserCredential userCondential =
            await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCondential.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        log(imageUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCondential.user!.uid)
            .set({
          // 'name': _enteredName,
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication failed.'),
        ),
      );
    }

    setState(() {
      isUploading = false;
    });

    _formkey.currentState!.save();
    log(_enteredEmail);
    log(_enteredPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 90,
                  left: 20,
                  right: 20,
                ),
                width: 150,
                child: Image.asset(
                  'assets/images/chat.png',
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formkey,
                      child: Column(
                        children: [
                          if (!isLogin)
                            UserImagePicker(
                              onPickImage: (File pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          if (!isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              onSaved: (newValue) {
                                _enteredUsername = newValue!;
                              },
                              validator: (value) {
                                if (value == null || value.trim().length < 4) {
                                  return 'Please enter at least 4 characters.';
                                }
                                return null;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                            ),
                            onSaved: (newValue) {
                              _enteredEmail = newValue!;
                            },
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'It isn\'t valid Email.';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            onSaved: (newValue) {
                              _enteredPassword = newValue!;
                            },
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.trim().length < 6) {
                                return 'Password can\'t be empty.';
                              }
                              return null;
                            },
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          if (isUploading) const CircularProgressIndicator(),
                          if (!isUploading)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              onPressed: submit,
                              child: Text(isLogin ? 'Login' : 'SignUp'),
                            ),
                          const SizedBox(height: 20),
                          if (!isUploading)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                });
                              },
                              child: Text(isLogin
                                  ? 'Create an account'
                                  : 'I already have an account'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
