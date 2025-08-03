using Dapper;
using DocumentFormat.OpenXml.Office2010.Excel;
using Irony.Parsing;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioProductos
    {
        Task<IEnumerable<Producto>> ObtenerTodos(int usuarioId);
        Task Crear(Producto producto);
        Task<Producto?> ObtenerPorId(int usuarioId, int id);
        Task Actualizar(int usuarioId, Producto producto);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioProductos : IRepositorioProductos
    {
        private readonly string connectionString;

        public RepositorioProductos(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Producto>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Producto>(
                "procObtenerProductos",
                new
                {
                    elementoObtenerId = 0,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(Producto producto)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblProductos (Nombre, ProductoCategoriaId, SKU)
                    VALUES (@Nombre, @ProductoCategoriaId, @SKU);

                    SELECT SCOPE_IDENTITY();
                ",
                producto
            );

            producto.ProductoId = id;
        }

        public async Task<Producto?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Producto>(
                "procObtenerProductos",
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Actualizar(int usuarioId, Producto producto)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Producto>(
                "procAlteraProductos",
                new
                {
                    elementoAlterarId = producto.ProductoId,
                    nombre = producto.Nombre,
                    productoCategoriaId = producto.ProductoCategoriaId,
                    sku = producto.SKU,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Producto>(
                "procAlteraProductos",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Producto eliminado",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
