using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCompraCategorias
    {
        Task<IEnumerable<CompraCategoria>> ObtenerTodos();
        Task Crear(CompraCategoria categoria);
        Task<CompraCategoria?> ObtenerPorId(int id);
        Task Actualizar(int usuarioId, CompraCategoria categoria);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioCompraCategorias : IRepositorioCompraCategorias
    {
        private readonly string connectionString;

        public RepositorioCompraCategorias(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<CompraCategoria>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<CompraCategoria>(
                @"
                    SELECT * FROM TblComprasCategorias
                "
            );
        }

        public async Task Crear(CompraCategoria categoria)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblComprasCategorias (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                categoria
            );

            categoria.CompraCategoriaId = id;
        }

        public async Task<CompraCategoria?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<CompraCategoria>(
                @"
                    SELECT * FROM TblComprasCategorias WHERE CompraCategoriaId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(int usuarioId, CompraCategoria categoria)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<CompraCategoria>(
                "procAlteraComprasCategorias",
                new
                {
                    elementoAlterarId = categoria.CompraCategoriaId,
                    nombre = categoria.Nombre,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<CompraCategoria>(
                "procAlteraComprasCategorias",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Categoria eliminada",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
