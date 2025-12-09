import 'package:flutter/material.dart';
import 'verifikasiAkun_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedTim;
  String? selectedInstansi;
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final waController = TextEditingController();
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "BATASKU",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                width: 120,
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "mobile",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Lengkapi Form Pendaftaran",
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 15),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.group),
                        labelText: "Pilih Tim PPB Des",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "pusat", child: Text("Pusat")),
                        DropdownMenuItem(
                          value: "provinsi",
                          child: Text("Provinsi"),
                        ),
                        DropdownMenuItem(
                          value: "kabupaten",
                          child: Text("Kabupaten/Kota"),
                        ),
                      ],
                      validator: (val) => val == null ? "Harus dipilih" : null,
                      onChanged: (val) => selectedTim = val,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance),
                        labelText: "Pilih Instansi",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "kemendagri",
                          child: Text("Kemendagri"),
                        ),
                        DropdownMenuItem(value: "big", child: Text("BIG")),
                      ],
                      validator: (val) => val == null ? "Harus dipilih" : null,
                      onChanged: (val) => selectedInstansi = val,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: "Nama",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Harus diisi" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        hintText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Harus diisi" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: waController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone),
                        hintText: "Nomor WhatsApp",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Harus diisi" : null,
                    ),
                    const SizedBox(height: 15),

                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          fileName = "dokumen_sk.pdf"; // placeholder
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("File $fileName dipilih")),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Unggah Dokumen SK Tim"),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0F4571),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              fileName != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Pendaftaran berhasil!"),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VerifikasiAkunPage(),
                              ),
                            );
                          } else if (fileName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap unggah dokumen SK"),
                              ),
                            );
                          }
                        },
                        child: const Text("Daftar"),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "Konfirmasi username dan kata sandi akan dikirim melalui email setelah verifikasi unggah dokumen SK Tim",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
