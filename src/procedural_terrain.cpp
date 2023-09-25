#include "procedural_terrain.hpp"

namespace pt
{
	void ProceduralTerrain::_bind_methods()
	{
		REGISTER_VALUE(ProceduralTerrain, godot::Variant::INT, chunk_size)
		REGISTER_VALUE(ProceduralTerrain, godot::Variant::INT, load_range)
		REGISTER_VALUE(ProceduralTerrain, godot::Variant::INT, vertex_width)
		REGISTER_VALUE(ProceduralTerrain, godot::Variant::OBJECT, material)
	}

	godot::Vector3 ProceduralTerrain::get_camera_position()
	{
		return {};
	}

	ProceduralTerrain::ProceduralTerrain()
		: chunk_size(10), load_range(2), vertex_width(10)
	{
	}

	void ProceduralTerrain::_process(double delta)
	{
		cleanup_old_chunks();
		generate_missing_chunks();
	}

	void ProceduralTerrain::cleanup_old_chunks()
	{
		const auto camera_position = get_camera_position();

		const auto camera_chunk_position = godot::Vector2i(round(camera_position.x / chunk_size),
		                                                   round(camera_position.z / chunk_size));
		for (const auto elem : loaded_chunks)
		{
			const auto key = elem.key;
			const auto distance_2d = std::max(abs(camera_chunk_position.x - key.x),
			                                  abs(camera_chunk_position.y - key.y));
			if (distance_2d > load_range)
			{
				loaded_chunks[key]->queue_free();
			}
			loaded_chunks.erase(key);
		}
	}

	void ProceduralTerrain::generate_missing_chunks()
	{
		const auto camera_position = get_camera_position();
		const auto camera_chunk_position = godot::Vector2i(round(camera_position.x / chunk_size),
		                                                   round(camera_position.z / chunk_size));

		for (int x = camera_chunk_position.x - load_range; x <= camera_chunk_position.x + load_range; ++x)
		{
			for (int y = camera_chunk_position.y - load_range; y <= camera_chunk_position.y + load_range; ++y)
			{
				const auto pos2d = godot::Vector2i(x, y);
				if (!loaded_chunks.has(pos2d))
				{
					const auto chunk = memnew(Chunk);
					chunk->init(pos2d, chunk_size, &noise, vertex_width, material);
					loaded_chunks[pos2d] = chunk;
					add_child(chunk);
				}
			}
		}
	}
}
