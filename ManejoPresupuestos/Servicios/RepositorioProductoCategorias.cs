using Dapper;
using DocumentFormat.OpenXml.Office2010.Excel;
using Irony.Parsing;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioProductoCategorias
    {
        Task<IEnumerable<ProductoCategoria>> ObtenerTodos();
        Task Crear(ProductoCategoria categoria);
        Task<ProductoCategoria?> ObtenerPorId(int id);
        Task Actualizar(int usuarioId, ProductoCategoria categoria);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioProductoCategorias : IRepositorioProductoCategorias
    {
        private readonly string connectionString;

        public RepositorioProductoCategorias(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<ProductoCategoria>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<ProductoCategoria>(
                @"
                    SELECT * FROM TblProductosCategorias
                "
            );
        }

        public async Task Crear(ProductoCategoria categoria)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblProductosCategorias (Nombre)
                    VALUES (@Nombre);

                    SELECT SCOPE_IDENTITY();
                ",
                categoria
            );

            categoria.ProductoCategoriaId = id;
        }

        public async Task<ProductoCategoria?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<ProductoCategoria>(
                @"
                    SELECT * FROM TblProductosCategorias WHERE ProductoCategoriaId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(int usuarioId, ProductoCategoria categoria)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<ProductoCategoria>(
                "procAlteraProductosCategorias",
                new
                {
                    elementoAlterarId = categoria.ProductoCategoriaId,
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

            await connection.QueryFirstOrDefaultAsync<ProductoCategoria>(
                "procAlteraProductosCategorias",
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
