// File: Servicios/RepositorioCompraCategoriasV2.cs
using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCompraCategoriasV2
    {
        Task<IEnumerable<CompraCategoriaV2>> ObtenerTodosActivos();
        Task<IEnumerable<CompraCategoriaV2>> ObtenerTodosIncluyendoInactivos();
        Task<CompraCategoriaV2?> ObtenerPorId(int id);
        Task<int> Crear(int usuarioId, CompraCategoriaV2 categoria);
        Task Actualizar(int usuarioId, CompraCategoriaV2 categoria);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioCompraCategoriasV2 : IRepositorioCompraCategoriasV2
    {
        private readonly string connectionString;

        public RepositorioCompraCategoriasV2(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<CompraCategoriaV2>> ObtenerTodosActivos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraCategoriaV2>(
                @"SELECT CompraCategoriaId, Nombre, EstaActivo
                  FROM dbo.TblComprasCategorias
                  WHERE EstaActivo = 1
                  ORDER BY Nombre;"
            );
        }

        public async Task<IEnumerable<CompraCategoriaV2>> ObtenerTodosIncluyendoInactivos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraCategoriaV2>(
                @"SELECT CompraCategoriaId, Nombre, EstaActivo
                  FROM dbo.TblComprasCategorias
                  ORDER BY EstaActivo DESC, Nombre;"
            );
        }

        public async Task<CompraCategoriaV2?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CompraCategoriaV2>(
                @"SELECT CompraCategoriaId, Nombre, EstaActivo
                  FROM dbo.TblComprasCategorias
                  WHERE CompraCategoriaId = @id;",
                new { id }
            );
        }

        public async Task<int> Crear(int usuarioId, CompraCategoriaV2 categoria)
        {
            using var connection = new SqlConnection(connectionString);
            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasCategoriasV2",
                new
                {
                    elementoAlterarId = 0,
                    nombre = categoria.Nombre,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo crear la categoría.");

            categoria.CompraCategoriaId = res.ElementoId;
            return res.ElementoId;
        }

        public async Task Actualizar(int usuarioId, CompraCategoriaV2 categoria)
        {
            using var connection = new SqlConnection(connectionString);
            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasCategoriasV2",
                new
                {
                    elementoAlterarId = categoria.CompraCategoriaId,
                    nombre = categoria.Nombre,
                    loginId = usuarioId,
                    actualizar = 1,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo actualizar la categoría.");
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            var res = await connection.QueryFirstOrDefaultAsync<SpResult>(
                "procAlteraComprasCategoriasV2",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Categoría eliminada",
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );

            if (res is null || !string.Equals(res.Result, "success", StringComparison.OrdinalIgnoreCase))
                throw new Exception(res?.Message ?? "No se pudo borrar la categoría.");
        }
    }
}