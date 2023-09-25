#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/fast_noise_lite.hpp>

#include "chunk.hpp"
#include "godot_cpp/templates/hash_map.hpp"

#define DECLARE_VALUE(type, name) \
	type name; \
	void set_##name(type in_##name) { name = in_##name; }\
	type get_##name() { return name; }

#define REGISTER_VALUE(class, type, name) \
	::godot::ClassDB::bind_method(::godot::D_METHOD("get_" #name), &class::get_##name); \
	::godot::ClassDB::bind_method(::godot::D_METHOD("set_" #name, "in_" #name), &class::set_##name); \
	::godot::ClassDB::add_property(get_class_static(), { type, #name }, "set_" #name, "get_" #name);

namespace pt
{
	class ProceduralTerrain : public godot::Node3D
	{
		GDCLASS(ProceduralTerrain, Node3D)

		DECLARE_VALUE(int, chunk_size)
		DECLARE_VALUE(int, load_range)
		DECLARE_VALUE(int, vertex_width)
		DECLARE_VALUE(godot::Ref<godot::Material>, material)

		void cleanup_old_chunks();
		void generate_missing_chunks();

	protected:
		static void _bind_methods();
	public:
		godot::Vector3 get_camera_position();

		ProceduralTerrain();

		void _process(double delta) override;

		godot::HashMap<godot::Vector2i, Chunk*> loaded_chunks;
		godot::FastNoiseLite noise;
	};
}
