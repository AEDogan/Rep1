// admin_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';
import 'services/coffee_assets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  void _login() {
    if (_usernameController.text == 'admin' && _passwordController.text == 'password123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else {
      setState(() {
        _error = 'Geçersiz kullanıcı adı veya şifre';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Girişi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.orange),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Giriş Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allProducts = [...provider.drinks, ...provider.snacks];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: allProducts.length,
        itemBuilder: (context, index) {
          final product = allProducts[index];
          return ListTile(
            leading: product.imageUrl.isNotEmpty 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            product.imageUrl, 
                            width: 50, 
                            height: 50, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee),
                          )
                        : Image.network(
                            product.imageUrl, 
                            width: 50, 
                            height: 50, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee),
                          ),
                  )
                : const Icon(Icons.coffee),
            title: Text(product.name),
            subtitle: Text('${product.basePrice} TL - ${product.category == 'drink' ? 'İçecek' : 'Atıştırmalık'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductEditorScreen(product: product)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, provider, product),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductEditorScreen()),
        ),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil?'),
        content: Text('${product.name} öğesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              provider.deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProductEditorScreen extends StatefulWidget {
  final Product? product;

  const ProductEditorScreen({super.key, this.product});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late bool _isInfiniteStock;
  late int _stockQuantity;
  late List<ModifierGroup> _modifierGroups;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product != null ? widget.product!.basePrice.toStringAsFixed(0) : '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _category = widget.product?.category ?? 'drink';
    _isInfiniteStock = widget.product?.isInfiniteStock ?? true;
    _stockQuantity = widget.product?.stockQuantity ?? 0;
    _modifierGroups = widget.product != null ? List.from(widget.product!.modifierGroups) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _showPresetPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Jenerik Kahve & Ürün Kataloğu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Şeffaf cam bardak & katmanlı hazır görseller", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: CoffeeAssets.presets.length,
                      itemBuilder: (_, index) {
                        final preset = CoffeeAssets.presets[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _nameController.text = preset.name;
                              _descriptionController.text = preset.description;
                              _priceController.text = preset.defaultPrice.toStringAsFixed(0);
                              _imageUrlController.text = preset.imageUrl;
                              _category = preset.category;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${preset.name} bilgileri forma aktarıldı! ✨"),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      preset.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.orange.shade50,
                                        child: const Icon(Icons.coffee, color: Colors.orange),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${preset.defaultPrice.toStringAsFixed(0)} TL • ${preset.category == 'drink' ? 'İçecek' : 'Tatlı'}",
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        basePrice: double.tryParse(_priceController.text.trim()) ?? 0,
        category: _category,
        imageUrl: _imageUrlController.text.trim(),
        isInfiniteStock: _isInfiniteStock,
        stockQuantity: _stockQuantity,
        modifierGroups: _modifierGroups,
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.product == null) {
        provider.addProduct(product);
      } else {
        provider.updateProduct(product);
      }
      Navigator.pop(context);
    }
  }

  void _addModifierGroup() async {
    final result = await showDialog<ModifierGroup>(
      context: context,
      builder: (context) => const ModifierGroupDialog(),
    );
    if (result != null) {
      setState(() {
        _modifierGroups.add(result);
      });
    }
  }

  void _editModifierGroup(int index) async {
    final result = await showDialog<ModifierGroup>(
      context: context,
      builder: (context) => ModifierGroupDialog(group: _modifierGroups[index]),
    );
    if (result != null) {
      setState(() {
        _modifierGroups[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrlController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Jenerik Görsel Seçim Bannerı
            InkWell(
              onTap: _showPresetPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.amber.shade50],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jenerik Görsellerden Seç (15 Çeşit)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          Text("Tek tıkla isim, fiyat ve şeffaf cam bardak görselini doldur", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Görsel Önizlemesi
            if (hasImage)
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ürün Adı', border: OutlineInputBorder()),
              validator: (val) => val == null || val.trim().isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Fiyat (TL)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Gerekli' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'drink', child: Text('İçecek')),
                      DropdownMenuItem(value: 'snack', child: Text('Atıştırmalık')),
                    ],
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Görsel URL',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {}),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              title: const Text('Sınırsız Stok'),
              value: _isInfiniteStock,
              onChanged: (val) => setState(() => _isInfiniteStock = val),
            ),
            if (!_isInfiniteStock)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  initialValue: _stockQuantity.toString(),
                  decoration: const InputDecoration(labelText: 'Stok Adedi', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => _stockQuantity = int.tryParse(val ?? '0') ?? 0,
                ),
              ),
            
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seçenek Grupları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addModifierGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Grup Ekle'),
                ),
              ],
            ),
            
            if (_modifierGroups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Henüz seçenek grubu eklenmemiş.', style: TextStyle(color: Colors.grey))),
              ),
            
            ...List.generate(_modifierGroups.length, (index) {
              final group = _modifierGroups[index];
              return Card(
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.options.length} Seçenek • ${group.isRequired ? 'Zorunlu' : 'İsteğe Bağlı'} • ${group.isMultiSelect ? 'Çoklu Seçim' : 'Tekli Seçim'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editModifierGroup(index)),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => setState(() => _modifierGroups.removeAt(index)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ÜRÜNÜ KAYDET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class ModifierGroupDialog extends StatefulWidget {
  final ModifierGroup? group;
  const ModifierGroupDialog({super.key, this.group});

  @override
  State<ModifierGroupDialog> createState() => _ModifierGroupDialogState();
}

class _ModifierGroupDialogState extends State<ModifierGroupDialog> {
  final _nameController = TextEditingController();
  bool _isRequired = false;
  bool _isMultiSelect = false;
  late List<ProductModifier> _options;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _isRequired = widget.group!.isRequired;
      _isMultiSelect = widget.group!.isMultiSelect;
      _options = List.from(widget.group!.options);
    } else {
      _options = [];
    }
  }

  void _addOption() async {
    final result = await showDialog<ProductModifier>(
      context: context,
      builder: (context) => const ModifierOptionDialog(),
    );
    if (result != null) {
      setState(() {
        _options.add(result);
      });
    }
  }

  void _editOption(int index) async {
    final result = await showDialog<ProductModifier>(
      context: context,
      builder: (context) => ModifierOptionDialog(modifier: _options[index]),
    );
    if (result != null) {
      setState(() {
        _options[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group == null ? 'Yeni Seçenek Grubu' : 'Grubu Düzenle'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Grup Adı (Örn: BOYUT SEÇİMİ)'),
              ),
              SwitchListTile(
                title: const Text('Zorunlu mu?'),
                value: _isRequired,
                onChanged: (val) => setState(() => _isRequired = val),
              ),
              SwitchListTile(
                title: const Text('Çoklu Seçim (Tıklama kutusu)'),
                subtitle: const Text('Kapalı ise tekli seçim (buton) olur'),
                value: _isMultiSelect,
                onChanged: (val) => setState(() => _isMultiSelect = val),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seçenekler', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _addOption, icon: const Icon(Icons.add_circle, color: Colors.green)),
                ],
              ),
              ...List.generate(_options.length, (index) {
                final opt = _options[index];
                return ListTile(
                  dense: true,
                  title: Text(opt.name),
                  subtitle: Text(opt.price == 0 ? 'Ücretsiz' : '+ ${opt.price} TL'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editOption(index)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => setState(() => _options.removeAt(index))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(
                context,
                ModifierGroup(
                  id: widget.group?.id ?? DateTime.now().toString(),
                  name: _nameController.text,
                  isRequired: _isRequired,
                  isMultiSelect: _isMultiSelect,
                  options: _options,
                ),
              );
            }
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}

class ModifierOptionDialog extends StatefulWidget {
  final ProductModifier? modifier;
  const ModifierOptionDialog({super.key, this.modifier});

  @override
  State<ModifierOptionDialog> createState() => _ModifierOptionDialogState();
}

class _ModifierOptionDialogState extends State<ModifierOptionDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.modifier != null) {
      _nameController.text = widget.modifier!.name;
      _priceController.text = widget.modifier!.price.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.modifier == null ? 'Yeni Seçenek' : 'Seçeneği Düzenle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Seçenek Adı (Örn: Büyük)'),
          ),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Fark Ücreti (TL)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(
                context,
                ProductModifier(
                  id: widget.modifier?.id ?? DateTime.now().toString(),
                  name: _nameController.text,
                  price: double.tryParse(_priceController.text) ?? 0,
                ),
              );
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
