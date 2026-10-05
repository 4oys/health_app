import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../data/auth_repository.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen(
      {super.key,
      required this.repository,
      required this.auth,
      required this.onComplete});
  final HealthRepository repository;
  final AuthRepository auth;
  final VoidCallback onComplete;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: 'Александр');
  final email = TextEditingController();
  final password = TextEditingController();
  Goal goal = Goal.lose;
  bool consent = false;
  bool visible = false;
  bool login = false;
  bool appleLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (login) {
      final accepted = await widget.auth.signIn(email.text, password.text);
      if (!mounted) return;
      if (accepted) {
        widget.onComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверная почта или пароль')));
      }
      return;
    }
    if (!consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Подтвердите согласие с условиями использования')));
      return;
    }
    final user = await widget.repository.user();
    await widget.repository.saveUser(user.copyWith(
        name: name.text.trim(), email: email.text.trim(), goal: goal));
    await widget.auth.register(email.text, password.text);
    if (mounted) widget.onComplete();
  }

  Future<void> appleSignIn() async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Вход через Apple доступен на iPhone.')));
      return;
    }
    if (!login && !consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Подтвердите согласие с условиями использования')));
      return;
    }
    if (appleLoading) return;
    setState(() => appleLoading = true);
    try {
      final account = await widget.auth.signInWithApple();
      final user = await widget.repository.user();
      if ((account.name != null && account.name != user.name) ||
          (account.email != null && account.email != user.email)) {
        await widget.repository.saveUser(user.copyWith(
          name: account.name ?? user.name,
          email: account.email ?? user.email,
        ));
      }
      if (mounted) widget.onComplete();
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Не удалось выполнить вход через Apple.')));
      }
    } on AppleSignInException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Не удалось выполнить вход через Apple.')));
      }
    } finally {
      if (mounted) setState(() => appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: SingleChildScrollView(
                  child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Form(
            key: form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back_ios_new, size: 18)),
                        const Text('●  • •',
                            style: TextStyle(color: AppColors.green)),
                        TextButton(
                            onPressed: () => setState(() => login = !login),
                            child: Text(login ? 'Создать' : 'Войти'))
                      ]),
                  const SizedBox(height: 30),
                  Center(
                      child: Container(
                          width: 65,
                          height: 65,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17)),
                          child: Image.asset('assets/logo.png'))),
                  const SizedBox(height: 18),
                  Center(
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xFFCEFAEE),
                              borderRadius: BorderRadius.circular(30)),
                          child: const Text('ДОБРО ПОЖАЛОВАТЬ',
                              style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)))),
                  const SizedBox(height: 8),
                  Text(login ? 'Вход в аккаунт' : 'Создание аккаунта',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const Text(
                      'Начните путь к здоровому питанию, балансу\nсил и энергии каждый день',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  if (!login) ...[
                    const _Label('Ваше имя'),
                    TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Александр'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Укажите имя'
                            : null),
                    const SizedBox(height: 16),
                  ],
                  const _Label('Электронная почта'),
                  TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          hintText: 'alexander@example.com'),
                      validator: (v) => v == null ||
                              !RegExp(r'^[^@ ]+@[^@ ]+\.[^@ ]+$').hasMatch(v)
                          ? 'Укажите корректную почту'
                          : null),
                  const SizedBox(height: 16),
                  _Label(login ? 'Пароль' : 'Придумайте пароль'),
                  TextFormField(
                      controller: password,
                      obscureText: !visible,
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => visible = !visible),
                              icon: Icon(visible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined))),
                      validator: (v) => v == null || v.length < 8
                          ? 'Минимум 8 символов'
                          : null),
                  if (!login) ...[
                    const SizedBox(height: 20),
                    const _Label('Ваша основная цель'),
                    Row(children: [
                      for (final g in Goal.values)
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                    onTap: () => setState(() => goal = g),
                                    child: Container(
                                        height: 68,
                                        decoration: BoxDecoration(
                                            color: goal == g
                                                ? AppColors.mint
                                                : Colors.white,
                                            border: Border.all(
                                                color: goal == g
                                                    ? AppColors.green
                                                    : const Color(0xFFDCE5EE),
                                                width: goal == g ? 2 : 1),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  g == Goal.lose
                                                      ? Icons.trending_down
                                                      : g == Goal.maintain
                                                          ? Icons.balance
                                                          : Icons
                                                              .fitness_center,
                                                  size: 19,
                                                  color: AppColors.green),
                                              Text(g.title,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ])))))
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      Checkbox(
                          value: consent,
                          onChanged: (v) =>
                              setState(() => consent = v ?? false)),
                      const Expanded(
                          child: Text(
                              'Согласен с условиями использования и обработкой персональных данных здоровья',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.muted)))
                    ]),
                  ],
                  const SizedBox(height: 15),
                  PrimaryButton(
                      text: login ? 'Войти' : 'Продолжить', onPressed: submit),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: Text('ИЛИ ЧЕРЕЗ',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted))),
                  SizedBox(
                      height: 44,
                      child: FilledButton(
                          onPressed: appleLoading ? null : appleSignIn,
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.black),
                          child: const Text('●  Продолжить с Apple'))),
                  const SizedBox(height: 15),
                  TextButton(
                      onPressed: () => setState(() => login = !login),
                      child: Text(login
                          ? 'Нет аккаунта? Создать'
                          : 'Уже есть аккаунт? Войти')),
                ])),
      ))));
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink)));
}
