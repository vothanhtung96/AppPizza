import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pizza_app_vs_010/service/database.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/widget/app_constant.dart';
import 'package:pizza_app_vs_010/widget/widget_support.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, id;
  int? add;
  TextEditingController amountcontroller = TextEditingController();
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryController = TextEditingController();
  TextEditingController cvcController = TextEditingController();
  TextEditingController zipController = TextEditingController();
  bool showPaymentForm = false;
  String selectedAmount = '';

  getthesharedpref() async {
    wallet = await SharedPreferenceHelper().getUserWallet();
    id = await SharedPreferenceHelper().getUserId();

    print('💰 Wallet Debug Info:');
    print('  - User ID: $id');
    print('  - Wallet: $wallet');

    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: id == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Vui lòng đăng nhập để xem ví',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Đăng nhập'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        elevation: 2.0,
                        child: Container(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: Center(
                            child: Text(
                              "Wallet",
                              style: AppWidget.HeadlineTextFeildStyle(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.0),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 10.0,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
                        child: Row(
                          children: [
                            Image.asset(
                              "images/wallet.png",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 40.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Wallet",
                                  style: AppWidget.LightTextFeildStyle(),
                                ),
                                SizedBox(height: 5.0),
                                Text(
                                  "\$${wallet!}",
                                  style: AppWidget.boldTextFeildStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          "Add money",
                          style: AppWidget.semiBoldTextFeildStyle(),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAmountButton('100'),
                          _buildAmountButton('500'),
                          _buildAmountButton('1000'),
                          _buildAmountButton('2000'),
                        ],
                      ),
                      SizedBox(height: 50.0),
                      GestureDetector(
                        onTap: () {
                          openEdit();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.0),
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Color(0xFF008080),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "Add Money",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPaymentForm)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _buildPaymentForm(),
                  ),
              ],
            ),
    );
  }

  Widget _buildAmountButton(String amount) {
    bool isSelected = selectedAmount == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAmount = amount;
          showPaymentForm = true;
        });
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xFF008080) : Color(0xFFE9E2E2),
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? Color(0xFF008080).withOpacity(0.1) : Colors.white,
        ),
        child: Text(
          "\$$amount",
          style: TextStyle(
            color: isSelected ? Color(0xFF008080) : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Spacer(),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "TEST MODE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      "Add your payment information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showPaymentForm = false;
                          selectedAmount = '';
                          cardNumberController.clear();
                          expiryController.clear();
                          cvcController.clear();
                          zipController.clear();
                        });
                      },
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Card Information Section
                Row(
                  children: [
                    Text(
                      "Card information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // Scan card functionality
                      },
                      icon: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.blue,
                      ),
                      label: Text(
                        "Scan card",
                        style: TextStyle(color: Colors.blue),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Card Number
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cardNumberController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Card number",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            // Format card number as 4242 4242 4242 4242
                            String formatted = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (formatted.length > 16) {
                              formatted = formatted.substring(0, 16);
                            }
                            String result = '';
                            for (int i = 0; i < formatted.length; i++) {
                              if (i > 0 && i % 4 == 0) {
                                result += ' ';
                              }
                              result += formatted[i];
                            }
                            if (result != value) {
                              cardNumberController.value = TextEditingValue(
                                text: result,
                                selection: TextSelection.collapsed(
                                  offset: result.length,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.credit_card, color: Colors.white, size: 20),
                      SizedBox(width: 5),
                      Icon(Icons.credit_card, color: Colors.white, size: 20),
                      SizedBox(width: 5),
                      Icon(Icons.credit_card, color: Colors.white, size: 20),
                      SizedBox(width: 5),
                      Icon(Icons.credit_card, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Expiry and CVC
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: expiryController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "MM / YY",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            // Format expiry as MM/YY
                            String formatted = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (formatted.length > 4) {
                              formatted = formatted.substring(0, 4);
                            }
                            if (formatted.length > 2) {
                              formatted =
                                  '${formatted.substring(0, 2)}/${formatted.substring(2)}';
                            }
                            if (formatted != value) {
                              expiryController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cvcController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "CVC",
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  // Format CVC as 3 digits
                                  String formatted = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  if (formatted.length > 3) {
                                    formatted = formatted.substring(0, 3);
                                  }
                                  if (formatted != value) {
                                    cvcController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                        offset: formatted.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            Icon(
                              Icons.credit_card,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Billing Address Section
                Text(
                  "Billing address",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),

                // Country dropdown
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "United States",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // ZIP code
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: zipController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "ZIP",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Pay Button
                GestureDetector(
                  onTap: () {
                    _processPayment();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pay ₹$selectedAmount.00",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.lock, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Simulate payment processing
      await Future.delayed(Duration(seconds: 2));

      // Close loading
      Navigator.pop(context);

      // Process payment
      await makePayment(selectedAmount);

      // Close payment form
      setState(() {
        showPaymentForm = false;
        selectedAmount = '';
      });
    } catch (e) {
      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Payment failed: ${e.toString()}"),
        ),
      );
    }
  }

  Future<void> makePayment(String amount) async {
    try {
      paymentIntent = await createPaymentIntent(amount, 'INR');
      // Temporarily disabled Stripe functionality
      // await Stripe.instance
      //     .initPaymentSheet(
      //         paymentSheetParameters: SetupPaymentSheetParameters(
      //             paymentIntentClientSecret: paymentIntent!['client_secret'],
      //             // applePay: const PaymentSheetApplePay(merchantCountryCode: '+92',),
      //             // googlePay: const PaymentSheetGooglePay(testEnv: true, currencyCode: "US", merchantCountryCode: "+92"),
      //             style: ThemeMode.dark,
      //             merchantDisplayName: 'Adnan'))
      //     .then((value) {});

      ///now finally display payment sheeet
      displayPaymentSheet(amount);
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayPaymentSheet(String amount) async {
    try {
      // Temporarily disabled Stripe functionality
      add = int.parse(wallet!) + int.parse(amount);
      await SharedPreferenceHelper().saveUserWallet(add.toString());
      await DatabaseMethods().UpdateUserwallet(id!, {"Wallet": add.toString()});
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  Text("Payment Successful (Demo)"),
                ],
              ),
            ],
          ),
        ),
      );
      await getthesharedpref();
      // ignore: use_build_context_synchronously

      paymentIntent = null;
    } catch (e) {
      print('Error is:---> $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(content: Text("Payment Failed")),
      );
    }
  }

  //  Future<Map<String, dynamic>>
  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      // ignore: avoid_print
      print('Payment Intent Body->>> ${response.body.toString()}');
      return jsonDecode(response.body);
    } catch (err) {
      // ignore: avoid_print
      print('err charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;

    return calculatedAmout.toString();
  }

  Future openEdit() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.cancel),
                  ),
                  SizedBox(width: 60.0),
                  Center(
                    child: Text(
                      "Add Money",
                      style: TextStyle(
                        color: Color(0xFF008080),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Text("Amount"),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: amountcontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter Amount',
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    makePayment(amountcontroller.text);
                  },
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Color(0xFF008080),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text("Pay", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
