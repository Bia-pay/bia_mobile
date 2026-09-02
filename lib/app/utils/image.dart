

import 'dart:math';

// --------------- SVG IMAGES ------------------
const appLogoPng = 'assets/svg/logo-two.png';
const logoPng = 'assets/svg/logo-one.png';
const splashLogo = 'assets/svg/logo.png';
const biaBLogo = 'assets/svg/logo-bia.png';
const faceIdSvg = 'assets/svg/scan-face.svg';
const qrCodeSvg = 'assets/svg/qr-code.svg';
const fingerPrint = 'assets/svg/fingerprint.svg';
const onboardingFirstPng = 'assets/svg/slide-one.png';
const onboardingFirstSvg = 'assets/svg/slide-one.svg';
const onboardingSecondPng = 'assets/svg/slide-two.png';
const onboardingSecondSvg = 'assets/svg/slide-two.svg';
const onboardingThirdSvg = 'assets/svg/slide-three.svg';
const onboardingFourthSvg = 'assets/svg/slide-four.svg';
const vector = 'assets/svg/create-account-vector.svg';
const vectorOne = 'assets/svg/create-account-vector-one.svg';
const arrowBackIcon = 'assets/svg/arrowback.svg';
const arrowBackIconWhite = 'assets/svg/arrowbackwhite.svg';
const appLogoBlack = 'assets/svg/applogoblack.svg';
const appLogoFull = 'assets/svg/logo-one.png';
const bell = 'assets/svg/bell.svg';
const send = 'assets/svg/send.svg';
const atm = 'assets/svg/atm.png';
const editSvg = 'assets/svg/edit.svg';
const cancelSvg = 'assets/svg/cancel.svg';
const successSvg = 'assets/svg/success-transfer.svg';
const scanner = 'assets/svg/scan.svg';
const tiktok = 'assets/svg/tik.png';
const bank = 'assets/svg/bank.png';
const mic = 'assets/svg/mic.svg';
const chatting = 'assets/svg/chatting.svg';
const login = 'assets/images/login.png';
const successWhiteBg = 'assets/images/successWhiteBg.png';
const successs = 'assets/svg/successs.svg';




// ------------- SVG ICONS -------------------

// --------------- PNG IMAGES -----------------
const backgroundImage = 'assets/image/bg.png';
const cameraImages = 'assets/image/camera.png';
const NoChatImage = 'assets/image/nochat.png';
const NoChatImageDark = 'assets/image/nochatdark.png';

String getRandomDiceBearAvatar() {
  final styles = [
    'adventurer',
    'lorelei',
    'avataaars',
    'bottts',
    'fun-emoji',
    'pixel-art',
    'notionists',
    'croodles'
  ];
  final style = styles[Random().nextInt(styles.length)];
  final seed = Random().nextInt(1000000).toString();
  return 'https://api.dicebear.com/7.x/$style/png?seed=$seed';
}

String getDiceBearAvatar(String seed) {
  final styles = [
    'adventurer',
    'lorelei',
    'avataaars',
    'bottts',
    'fun-emoji',
    'pixel-art',
    'notionists',
    'croodles'
  ];
  final styleIndex = seed.hashCode.abs() % styles.length;
  final style = styles[styleIndex];
  return 'https://api.dicebear.com/7.x/$style/png?seed=$seed';
}

