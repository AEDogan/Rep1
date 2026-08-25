// admin_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';

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
  late String _name;
  late String _description;
  late double _basePrice;
  late String _category;
  late String _imageUrl;
  late bool _isInfiniteStock;
  late int _stockQuantity;
  late List<ModifierGroup> _modifierGroups;

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _description = widget.product?.description ?? '';
    _basePrice = widget.product?.basePrice ?? 0;
    _category = widget.product?.category ?? 'drink';
    _imageUrl = widget.product?.imageUrl ?? '';
    _isInfiniteStock = widget.product?.isInfiniteStock ?? true;
    _stockQuantity = widget.product?.stockQuantity ?? 0;
    _modifierGroups = widget.product != null ? List.from(widget.product!.modifierGroups) : [];
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final product = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        description: _description,
        basePrice: _basePrice,
        category: _category,
        imageUrl: _imageUrl,
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              onSaved: (val) => _name = val!,
              validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
            ),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              onSaved: (val) => _description = val!,
            ),
            TextFormField(
              initialValue: _basePrice.toString(),
              decoration: const InputDecoration(labelText: 'Temel Fiyat (TL)'),
              keyboardType: TextInputType.number,
              onSaved: (val) => _basePrice = double.tryParse(val!) ?? 0,
            ),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: const [
                DropdownMenuItem(value: 'drink', child: Text('İçecek')),
                DropdownMenuItem(value: 'snack', child: Text('Atıştırmalık')),
              ],
              onChanged: (val) => setState(() => _category = val!),
            ),
            TextFormField(
              initialValue: _imageUrl,
              decoration: const InputDecoration(labelText: 'Görsel URL'),
              onSaved: (val) => _imageUrl = val!,
            ),
            SwitchListTile(
              title: const Text('Sınırsız Stok'),
              value: _isInfiniteStock,
              onChanged: (val) => setState(() => _isInfiniteStock = val),
            ),
            if (!_isInfiniteStock)
              TextFormField(
                initialValue: _stockQuantity.toString(),
                decoration: const InputDecoration(labelText: 'Stok Adedi'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _stockQuantity = int.tryParse(val!) ?? 0,
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
