import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../theme.dart';
import 'estrellas.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  Widget _placeholder() {
    return Container(
      height: 170,
      width: double.infinity,
      color: Mimi.rosaClaro,
      child: const Icon(Icons.cake_outlined, size: 56, color: Mimi.rosa),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shadowColor: const Color(0x33B71C1C),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            if (post.imagen.isEmpty)
              _placeholder()
            else
              Image.network(
                post.imagen,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORÍA (tags)
                  if (post.tags.isNotEmpty)
                    Text(
                      post.tags.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Mimi.rosa,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // TÍTULO
                  Text(
                    post.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Mimi.cacao,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // DESCRIPCIÓN
                  Text(
                    post.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Mimi.gris),
                  ),
                  const SizedBox(height: 10),
                  // VALORACIÓN
                  EstrellasPromedio(
                    promedio: post.promedioEstrellas,
                    total: post.numValoraciones,
                  ),
                  const SizedBox(height: 10),
                  // AUTOR, COMENTARIOS Y FECHA
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Mimi.rosa),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          post.autor,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Mimi.gris),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.chat_bubble_outline, size: 16, color: Mimi.rosa),
                      const SizedBox(width: 4),
                      Text(
                        '${post.numComentarios}',
                        style: const TextStyle(fontSize: 13, color: Mimi.gris),
                      ),
                      const Spacer(),
                      Text(
                        post.fechaFormateada,
                        style: const TextStyle(fontSize: 12, color: Mimi.gris),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
