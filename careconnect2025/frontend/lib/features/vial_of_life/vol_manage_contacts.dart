import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vol_api_service.dart';
import 'vol_home.dart'; // for ContactView model

class ManageContactsScreen extends StatefulWidget {
  final int patientId;
  const ManageContactsScreen({super.key, required this.patientId});

  @override
  State<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends State<ManageContactsScreen> {
  bool loading = true;
  String? error;

  // Full vial snapshot so we can round-trip without losing other fields
  String? vialId;
  String firstName = '';
  String lastName = '';
  String bloodType = '-';
  List<String> allergies = const [];
  List<String> medications = const [];
  List<String> conditions = const [];
  List<ContactView> contacts = const [];
  String tracker = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await VolApiService.getVial(widget.patientId);
      if (data == null) {
        setState(() {
          error = 'No data found.';
          loading = false;
        });
        return;
      }
      setState(() {
        vialId = (data['id'] ?? data['vialId'])?.toString();
        firstName = (data['firstName'] ?? '').toString();
        lastName = (data['lastName'] ?? '').toString();
        bloodType = (data['bloodType'] ?? '-').toString();
        allergies = List<String>.from(data['allergies'] ?? const []);
        medications = List<String>.from(data['medications'] ?? const []);
        conditions = List<String>.from(data['conditions'] ?? const []);
        tracker = (data['tracker'] ?? '').toString();
        contacts = (data['emergencyContacts'] as List? ?? const [])
            .map((c) => ContactView(
                  name: (c['name'] ?? '').toString(),
                  role: (c['role'] ?? '').toString(),
                  phone: (c['phone'] ?? '').toString(),
                  isPrimary: (c['isPrimary'] ?? false) == true,
                ))
            .toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data.';
        loading = false;
      });
    }
  }


  //Save function
  Future<void> _save() async {
    setState(() => loading = true);
    final flattened = contacts.map((c) {
      final prim = c.isPrimary ? 'PRIMARY' : '';
      return '${c.name}|${c.role}|${c.phone}|$prim';
    }).toList();

    final ok = await VolApiService.saveContacts(widget.patientId, flattened);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = 'Save failed.';
        loading = false;
      });
    }
  }

  void _addContact() async {
    final newC = await showDialog<ContactView>(
      context: context,
      builder: (_) => const _ContactDialog(),
    );
    if (newC != null) {
      setState(() {
        contacts = List<ContactView>.from(contacts)..add(newC);
      });
    }
  }

  void _editContact(int index) async {
    final c = contacts[index];
    final edited = await showDialog<ContactView>(
      context: context,
      builder: (_) => _ContactDialog(
        initialName: c.name,
        initialRole: c.role,
        initialPhone: c.phone,
        initialPrimary: c.isPrimary,
      ),
    );
    if (edited != null) {
      setState(() {
        contacts = List<ContactView>.from(contacts)..[index] = edited;
      });
    }
  }

  void _deleteContact(int index) {
    setState(() {
      contacts = List<ContactView>.from(contacts)..removeAt(index);
    });
  }

  void _setPrimary(int index) {
    setState(() {
      contacts = contacts
          .asMap()
          .entries
          .map((e) => ContactView(
                name: e.value.name,
                role: e.value.role,
                phone: e.value.phone,
                isPrimary: e.key == index,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Contacts')),
        body: Center(child: Text(error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Contacts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(c.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800, fontSize: 16)),
                                  ),
                                  if (c.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8EDFF),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text('PRIMARY',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF2446D2))),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${c.role} • ${c.phone}',
                                  style: TextStyle(color: Colors.black.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Make Primary',
                          icon: const Icon(Icons.star),
                          onPressed: () => _setPrimary(i),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editContact(i),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteContact(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Add Contact'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  final String? initialName;
  final String? initialRole;
  final String? initialPhone;
  final bool initialPrimary;
  const _ContactDialog({
    this.initialName,
    this.initialRole,
    this.initialPhone,
    this.initialPrimary = false,
  });

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController roleCtrl;
  late TextEditingController phoneCtrl;
  late bool isPrimary;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
    roleCtrl = TextEditingController(text: widget.initialRole ?? '');
    phoneCtrl = TextEditingController(text: widget.initialPhone ?? '');
    isPrimary = widget.initialPrimary;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    roleCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Relationship/Role'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]'))],
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: isPrimary,
              onChanged: (v) => setState(() => isPrimary = v ?? false),
              title: const Text('Primary contact'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                ContactView(
                  name: nameCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  isPrimary: isPrimary,
                ),
              );
            }
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
