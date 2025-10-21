// lib/features/professional_portal/presentation/screens/client_diet_screen.dart

import 'dart:io';
import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class ClientDietScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientDietScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  _ClientDietScreenState createState() => _ClientDietScreenState();
}

class _ClientDietScreenState extends State<ClientDietScreen> {
  final _repository = ProfessionalRepository();
  late Future<List<Map<String, dynamic>>> _dietPlansFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDietPlans();
  }

  void _loadDietPlans() {
    setState(() {
      _dietPlansFuture = _repository.getDietPlans(widget.clientId);
    });
  }

  Future<void> _pickAndUploadFile() async {
    // 1. Pedir para o usuário escolher um arquivo PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final planTitle = await _showTitleDialog(); // 2. Pedir um título

      if (planTitle != null && planTitle.isNotEmpty) {
        setState(() { _isUploading = true; });
        try {
          // 3. Fazer o upload
          await _repository.uploadDietPlan(
            file: file,
            planTitle: planTitle,
            clientId: widget.clientId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plano enviado com sucesso!'), backgroundColor: Colors.green),
          );
          _loadDietPlans(); // 4. Recarregar a lista
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
          );
        } finally {
          setState(() { _isUploading = false; });
        }
      }
    }
  }

  Future<String?> _showTitleDialog() {
    final titleController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Título do Plano'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Ex: Dieta - Fase 1"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(titleController.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPdf(String fileUrl) async {
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o arquivo: $fileUrl'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dietas de ${widget.clientName}'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _dietPlansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nenhum plano de dieta enviado.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                );
              }

              final plans = snapshot.data!;
              return ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final createdAt = DateTime.parse(plan['created_at']);
                  final formattedDate = DateFormat('dd/MM/yyyy \'às\' HH:mm').format(createdAt);

                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    title: Text(plan['plan_title']),
                    subtitle: Text('Enviado em $formattedDate'),
                    onTap: () => _openPdf(plan['file_path']),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Enviando plano...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.upload_file, color: Colors.black),
      ),
    );
  }
}