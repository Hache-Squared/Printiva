using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioProductos
    {
        Task<IEnumerable<Producto>> ObtenerTodos(int usuarioId, bool soloActivos = true);
        Task<Producto?> ObtenerPorId(int usuarioId, int id);
        Task Crear(int usuarioId, Producto producto);
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

        public async Task<IEnumerable<Producto>> ObtenerTodos(int usuarioId, bool soloActivos = true)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Producto>(
                "procObtenerProductos",
                new
                {
                    elementoObtenerId = 0,
                    loginId = usuarioId,
                    soloActivos = soloActivos ? 1 : 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Producto?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Producto>(
                "procObtenerProductos",
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId,
                    soloActivos = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(int usuarioId, Producto producto)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync(
                "procAlteraProductos",
                new
                {
                    elementoAlterarId = 0,
                    nombre = producto.Nombre,
                    productoCategoriaId = producto.ProductoCategoriaId,
                    sku = producto.SKU,
                    precioSugerido = producto.PrecioSugerido,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }


        public async Task Actualizar(int usuarioId, Producto producto)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync(
                "procAlteraProductos",
                new
                {
                    elementoAlterarId = producto.ProductoId,
                    nombre = producto.Nombre,
                    productoCategoriaId = producto.ProductoCategoriaId,
                    sku = producto.SKU,
                    precioSugerido = producto.PrecioSugerido,
                    loginId = usuarioId,
                    actualizar = 1,
                    borrar = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync(
                "procAlteraProductos",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Producto eliminado",
                    productoCategoriaId = 1,
                    sku = "",
                    precioSugerido = (decimal?)null,
                    loginId = usuarioId,
                    actualizar = 0,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
