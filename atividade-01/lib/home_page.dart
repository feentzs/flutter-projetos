import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  
  Map<String, dynamic>? _pokemonData;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _consultarPokemon() async {
    final nomePokemon = _controller.text.trim().toLowerCase();

    if (nomePokemon.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite o nome de um Pokémon.';
        _pokemonData = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _pokemonData = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$nomePokemon'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pokemonData = json.decode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Pokémon "$nomePokemon" não encontrado!';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao buscar dados. Tente novamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique sua internet.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achar Pokemon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(), 
                hintText: 'Digite o nome do Pokémon', 
                labelText: ' Nome do Pokémon', 
                  ),
              
                onSubmitted: (_) => _consultarPokemon(),
              ),
              const SizedBox(height: 16),
              

              FilledButton.icon(
                onPressed: _isLoading ? null : _consultarPokemon,
                icon: const Icon(Icons.catching_pokemon),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Consultar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    } else if (_pokemonData != null) {
      return _buildPokemonCard();
    }
    
    return const Column(
      children: [
        Icon(Icons.search, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Pesquise um Pokémon para ver seus dados.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPokemonCard() {
    final pesoKg = _pokemonData!['weight'] / 10;
    final alturaM = _pokemonData!['height'] / 10;
    final imageUrl = _pokemonData!['sprites']['other']['official-artwork']['front_default'] 
                  ?? _pokemonData!['sprites']['front_default'];
    final nome = _pokemonData!['name'].toString().toUpperCase();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 16),
            Text(
              nome,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${_pokemonData!['id'].toString().padLeft(3, '0')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Altura', '$alturaM m'),
                _buildInfoColumn('Peso', '$pesoKg kg'),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: (_pokemonData!['types'] as List).map((tipoInfo) {
                return Chip(
                  label: Text(
                    tipoInfo['type']['name'].toString().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}