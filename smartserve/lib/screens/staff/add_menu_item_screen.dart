import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  final MenuItem? itemToEdit; // NEW: If this is passed, we are in Edit Mode!

  const AddMenuItemScreen({Key? key, this.itemToEdit}) : super(key: key);

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(); // NEW

  String _selectedCategory = 'Meals';
  bool _isAvailable = true;

  final List<String> _categories = ['Meals', 'Snacks', 'Beverages', 'Desserts'];

  @override
  void initState() {
    super.initState();
    // NEW: If we are editing, pre-fill all the controllers!
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _descController.text = item.description;
      _priceController.text = item.price.toString();
      _imageController.text = item.imageUrl;
      _prepTimeController.text = item.preparationTime.toString();
      _caloriesController.text = item.calories;
      _ratingController.text = item.rating.toString();
      _tagsController.text = item.tags.join(', ');
      _ingredientsController.text = item.ingredients.join(', ');
      
      // Ensure category matches one of the dropdown options
      if (_categories.contains(item.category)) {
        _selectedCategory = item.category;
      }
      _isAvailable = item.isAvailable;
    } else {
      _ratingController.text = '4.0'; // Default rating for new items
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _prepTimeController.dispose();
    _caloriesController.dispose();
    _tagsController.dispose();
    _ingredientsController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<String> tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        List<String> ingredientsList = _ingredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        Map<String, dynamic> itemData = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'category': _selectedCategory,
          'price': double.parse(_priceController.text.trim()),
          'imageUrl': _imageController.text.trim(),
          'isAvailable': _isAvailable,
          'preparationTime': int.parse(_prepTimeController.text.trim()),
          'tags': tagsList,
          'ingredients': ingredientsList,
          'calories': _caloriesController.text.trim(),
          'rating': double.parse(_ratingController.text.trim()),
        };

        if (widget.itemToEdit == null) {
          // ADD MODE
          await _menuService.addMenuItem(itemData);
        } else {
          // EDIT MODE
          await FirebaseFirestore.instance.collection('menu_items').doc(widget.itemToEdit!.itemId).update(itemData);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemToEdit == null ? 'Item added successfully!' : 'Item updated successfully!'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.itemToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(isEditing ? 'Edit Item' : 'Add New Item', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B)))
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionTitle('Basic Info'),
              _buildTextField(_nameController, 'Item Name', Icons.fastfood, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(_descController, 'Description', Icons.description, maxLines: 3, isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(labelText: 'Category', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.inter()))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_priceController, 'Price (₹)', Icons.currency_rupee, isNumber: true, isRequired: true)),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Details & Media'),
              _buildTextField(_imageController, 'Image URL (Unsplash/Web)', Icons.image, isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_prepTimeController, 'Time (min)', Icons.timer, isNumber: true, isRequired: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_caloriesController, 'Calories', Icons.local_fire_department, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_ratingController, 'Rating (1-5)', Icons.star, isNumber: true, isRequired: true)),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Tags & Ingredients'),
              _buildTextField(_tagsController, 'Tags (comma separated e.g. Veg, Spicy)', Icons.label),
              const SizedBox(height: 16),
              _buildTextField(_ingredientsController, 'Ingredients (comma separated)', Icons.restaurant),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text('Available in stock right now?', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  value: _isAvailable,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isAvailable = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: Text(isEditing ? 'Update Menu Item' : 'Save Menu Item', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      validator: isRequired ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    );
  }
}