#include "chunk.hpp"

#include "godot_cpp/classes/collision_shape3d.hpp"
#include "godot_cpp/classes/concave_polygon_shape3d.hpp"
#include "godot_cpp/classes/mesh_instance3d.hpp"
#include "godot_cpp/classes/surface_tool.hpp"

namespace pt
{
	void Chunk::_bind_methods()
	{
	}

	void Chunk::init(godot::Vector2i in_position2d, int in_chunk_size, godot::FastNoiseLite* _in_noise,
		int _in_vertex_width, godot::Ref<godot::Material> in_material)
	{
		std::cout << "Spawned chunk : " << in_position2d.x << "x" << in_position2d.y << std::endl;
		position2d = in_position2d;
		chunk_size = in_chunk_size;
		noise = _in_noise;
		vertex_width = _in_vertex_width;
		material = in_material;
	}

	void Chunk::_ready()
	{
		Node3D::_ready();

		std::cout << "Chunk ready : " << position2d.x << "x" << position2d.y << std::endl;
		auto surface_tool = godot::SurfaceTool();

		surface_tool.begin(godot::Mesh::PRIMITIVE_TRIANGLES);


		const auto chunk_position = godot::Vector3(chunk_size * position2d.x, 0, chunk_size * position2d.y);

		auto vertices = godot::PackedVector3Array();
		const auto cell_width = chunk_size / static_cast<float>(vertex_width - 1);
		for (int x = 0; x < vertex_width; ++x)
		{
			for (int z = 0; z < vertex_width; ++z)
			{
				auto pos3d = chunk_position + godot::Vector3(x * cell_width, 0, z * cell_width) - godot::Vector3(
					chunk_size / 2, 0, chunk_size / 2);
				const auto scale = 0.2;
				pos3d.y += noise->get_noise_2d(pos3d.x * scale, pos3d.z * scale) * 100;

				surface_tool.set_uv(godot::Vector2(pos3d.x, pos3d.z));
				surface_tool.add_vertex(pos3d);
				vertices.append(pos3d);
			}
		}

		auto faces = godot::PackedVector3Array();
		for (int x = 0; x < vertex_width - 1; ++x)
		{
			for (int z = 0; z < vertex_width - 1; ++z)
			{
				faces.append(vertices[x * (vertex_width) + z]);
				faces.append(vertices[(x + 1) * (vertex_width) + z]);
				faces.append(vertices[x * (vertex_width) + z + 1]);
				faces.append(vertices[x * (vertex_width) + z + 1]);
				faces.append(vertices[(x + 1) * (vertex_width) + z]);
				faces.append(vertices[(x + 1) * (vertex_width) + z + 1]);
			}
		}

		for (int x = 0; x < vertex_width - 1; ++x)
		{
			for (int z = 0; z < vertex_width - 1; ++z)
			{
				surface_tool.add_index(x * (vertex_width) + z);
				surface_tool.add_index((x + 1) * (vertex_width) + z);
				surface_tool.add_index(x * (vertex_width) + z + 1);
				surface_tool.add_index(x * (vertex_width) + z + 1);
				surface_tool.add_index((x + 1) * (vertex_width) + z);
				surface_tool.add_index((x + 1) * (vertex_width) + z + 1);
			}
		}

		// Create the chunk's mesh from the SurfaceTool data.
		surface_tool.generate_normals();
		surface_tool.set_material(material);
		const auto array_mesh = surface_tool.commit();
		const auto mi = memnew(godot::MeshInstance3D);
		mi->set_mesh(array_mesh);
		add_child(mi);

		const auto convex_collision = memnew(godot::CollisionShape3D);
		const auto shape = godot::Ref<godot::ConcavePolygonShape3D>();
		shape->set_faces(faces);
		convex_collision->set_shape(shape);
		add_child(convex_collision);
		convex_collision->set_global_position(godot::Vector3(0, 0, 0));
	}
}
