#pragma once
#include "godot_cpp/classes/fast_noise_lite.hpp"
#include "godot_cpp/classes/material.hpp"
#include "godot_cpp/classes/node3d.hpp"

namespace pt
{
	class Chunk : public godot::Node3D
	{
		GDCLASS(Chunk, Node3D)

		godot::Ref<godot::Material> material;
		godot::FastNoiseLite* noise;
		godot::Vector2i position2d;
		int chunk_size;
		int vertex_width;

	protected:
		static void _bind_methods();

	public:
		void _ready() override;

		void init(godot::Vector2i in_position2d, int in_chunk_size, godot::FastNoiseLite* _in_noise,
		          int _in_vertex_width, godot::Ref<godot::Material> in_material);
	};
}
