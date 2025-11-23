using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioVentaRecetas
    {
        Task<IEnumerable<VentaReceta>> ObtenerTodos(int usuarioId);
        Task<IEnumerable<VentaReceta>> ObtenerPorVentaId(int ventaId, int usuarioId);
        Task<VentaReceta?> ObtenerPorId(int ventaRecetaId, int usuarioId);
        Task Crear(VentaReceta ventaReceta);
        Task Actualizar(VentaReceta ventaReceta);
        Task Borrar(int ventaRecetaId, int usuarioId);
        Task BorrarPorVentaId(int ventaId, int usuarioId);
    }

    public class RepositorioVentaRecetas : IRepositorioVentaRecetas
    {
        private readonly string connectionString;

        public RepositorioVentaRecetas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<VentaReceta>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<VentaReceta>(
                "procObtenerVentasRecetas",
                new { ElementoObtenerId = 0, loginId = usuarioId, ObtenerPorVentaId = 0 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<VentaReceta>> ObtenerPorVentaId(int ventaId, int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<VentaReceta>(
                "procObtenerVentasRecetas",
                new { ElementoObtenerId = ventaId, loginId = usuarioId, ObtenerPorVentaId = 1 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<VentaReceta?> ObtenerPorId(int ventaRecetaId, int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<VentaReceta>(
                "procObtenerVentasRecetas",
                new { ElementoObtenerId = ventaRecetaId, loginId = usuarioId, ObtenerPorVentaId = 0 },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(VentaReceta ventaReceta)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(@"
                INSERT INTO TblVentasRecetas 
                    (VentaId, RecetaId, Cantidad, CostoUnitario)
                VALUES 
                    (@VentaId, @RecetaId, @Cantidad, @CostoUnitario);
                SELECT CAST(SCOPE_IDENTITY() AS INT);
            ", ventaReceta);

            ventaReceta.VentaRecetaId = id;
        }

        public async Task Actualizar(VentaReceta ventaReceta)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.ExecuteAsync(
                "procAlteraVentasRecetas",
                new
                {
                    ElementoAlterarId = ventaReceta.VentaRecetaId,
                    VentaId = ventaReceta.VentaId,
                    RecetaId = ventaReceta.RecetaId,
                    Cantidad = ventaReceta.Cantidad,
                    CostoUnitario = ventaReceta.CostoUnitario,
                    loginId = 0,
                    Actualizar = 1,
                    Borrar = 0,
                    BorrarTodasPorVenta = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int ventaRecetaId, int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.ExecuteAsync(
                "procAlteraVentasRecetas",
                new
                {
                    ElementoAlterarId = ventaRecetaId,
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 1,
                    BorrarTodasPorVenta = 0
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task BorrarPorVentaId(int ventaId, int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.ExecuteAsync(
                "procAlteraVentasRecetas",
                new
                {
                    ElementoAlterarId = ventaId,
                    loginId = usuarioId,
                    Actualizar = 0,
                    Borrar = 0,
                    BorrarTodasPorVenta = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}