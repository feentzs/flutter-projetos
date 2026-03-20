import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; 
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  final TextEditingController _pokemonController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
 
  Map<String, dynamic>? _pokemonData;
  bool _isPokemonLoading = false;
  String _pokemonErrorMessage = '';


  bool _isMusicLoading = false;
  bool _isPlaying = false;
  String _musicErrorMessage = '';
  String? _currentTrackTitle;
  String? _currentTrackAuthor;
  String? _currentArtworkUrl;

  @override
  void initState() {
    super.initState();
   
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });


    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }


  void _buscarPokemonAleatorio() {

    final randomId = Random().nextInt(1010) + 1; 
    _pokemonController.text = randomId.toString(); 
    _consultarPokemon(randomId.toString());
  }


  Future<void> _consultarPokemon([String? busca]) async {
    final query = (busca ?? _pokemonController.text).trim().toLowerCase();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    await _audioPlayer.stop();

    setState(() {
      _isPokemonLoading = true;
      _pokemonErrorMessage = '';
      _pokemonData = null;
      

      _currentTrackTitle = null;
      _currentTrackAuthor = null;
      _currentArtworkUrl = null;
      _musicErrorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonData = data;
          _isPokemonLoading = false;
        });
        

        final nomePokemon = data['name'].toString();
        _searchAndPlayMusic(nomePokemon);

      } else if (response.statusCode == 404) {
        setState(() {
          _pokemonErrorMessage = 'Pokémon não encontrado!';
          _isPokemonLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _pokemonErrorMessage = 'Erro ao buscar dados do Pokémon.';
        _isPokemonLoading = false;
      });
    }
  }


  Future<void> _searchAndPlayMusic(String pokemonName) async {
    setState(() {
      _isMusicLoading = true;
      _musicErrorMessage = '';
    });

    try {
      final url = Uri.parse('https://itunes.apple.com/search?term=$pokemonName&entity=song&limit=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['resultCount'] > 0) {
          final track = data['results'][0];
          final previewUrl = track['previewUrl'];

          if (previewUrl != null) {
            await _audioPlayer.play(UrlSource(previewUrl));
            
            setState(() {
              _currentTrackTitle = track['trackName'];
              _currentTrackAuthor = track['artistName'];
              _currentArtworkUrl = track['artworkUrl100']?.replaceAll('100x100bb', '300x300bb');
              _isMusicLoading = false;
            });
          } else {
            setState(() {
              _musicErrorMessage = 'Música encontrada, mas sem áudio de prévia.';
              _isMusicLoading = false;
            });
          }
        } else {
          setState(() {
            _musicErrorMessage = 'Nenhuma música encontrada com o nome "$pokemonName".';
            _isMusicLoading = false;
          });
        }
      } else {
        throw Exception('Erro na Apple');
      }
    } catch (e) {
      print('Erro de música: $e');
      setState(() {
        _musicErrorMessage = 'Erro ao buscar a música tema.';
        _isMusicLoading = false;
      });
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex Musical', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pokemonController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(), 
                        hintText: 'Nome ou ID do Pokémon', 
                        prefixIcon: Icon(Icons.catching_pokemon)
                      ),
                      onSubmitted: (_) => _consultarPokemon(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  IconButton.filledTonal(
                    onPressed: _isPokemonLoading ? null : _buscarPokemonAleatorio,
                    icon: const Icon(Icons.shuffle),
                    iconSize: 32,
                    tooltip: 'Pokémon Aleatório',
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
        
              FilledButton.icon(
                onPressed: _isPokemonLoading ? null : () => _consultarPokemon(),
                icon: const Icon(Icons.search),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0), 
                  child: Text('Consultar')
                ),
              ),
              const SizedBox(height: 32),

              Center(child: _buildPokemonContent()),
              
              const SizedBox(height: 24),


              _buildMusicPlayerUI(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPokemonContent() {
    if (_isPokemonLoading) return const CircularProgressIndicator();
    if (_pokemonErrorMessage.isNotEmpty) {
      return Text(_pokemonErrorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16));
    }
    
    if (_pokemonData != null) {
      final imageUrl = _pokemonData!['sprites']['other']['official-artwork']['front_default'] ?? _pokemonData!['sprites']['front_default'];
      final nome = _pokemonData!['name'].toString().toUpperCase();
      
      return Column(
        children: [
          if (imageUrl != null) Image.network(imageUrl, height: 200),
          const SizedBox(height: 16),
          Text(nome, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('#${_pokemonData!['id'].toString().padLeft(3, '0')}', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMusicPlayerUI() {
    if (_isPokemonLoading) return const SizedBox.shrink(); 
    if (_isMusicLoading) return const Center(child: CircularProgressIndicator());
    

    if (_musicErrorMessage.isNotEmpty && _pokemonData != null) {
      return Center(
        child: Text(
          _musicErrorMessage, 
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
        )
      );
    }
    

    if (_currentTrackTitle != null) {
      return Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 12),
              if (_currentArtworkUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_currentArtworkUrl!, height: 100, width: 100, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              Text(_currentTrackTitle!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
              Text(_currentTrackAuthor!, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 56,
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                    onPressed: _togglePlayPause,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _pokemonController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
