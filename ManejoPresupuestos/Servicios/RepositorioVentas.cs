using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioVentas
    {
        Task<IEnumerable<Venta>> ObtenerTodos(int usuarioId);
        Task Crear(Venta venta);
        Task<Venta?> ObtenerPorId(int usuarioId, int id);
        Task Actualizar(int usuarioId, Venta venta);
        Task Borrar(int usuarioId, int id);
        Task VentaLogTransaccion(int usuarioId, Venta venta);
    }

    public class RepositorioVentas : IRepositorioVentas
    {
        private readonly string connectionString;

        public RepositorioVentas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task VentaLogTransaccion(int usuarioId, Venta venta)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QuerySingleAsync<int>(
                "procUpdateTransaccionesVentas",
                new
                {
                    Monto = venta.CostoTotal,
                    FechaTransaccion = venta.FechaCreacion,
                    UsuarioId = usuarioId,
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<Venta>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Venta>(
                "procObtenerVentas",
                new { loginId = usuarioId },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(Venta venta)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblVentas (ClienteId, Descripcion, CostoTotal, FechaCreacion, UsuarioId)
                    VALUES (@ClienteId, @Descripcion, @CostoTotal, @FechaCreacion, @UsuarioId);
                    SELECT SCOPE_IDENTITY();
                ",
                venta
            );

            venta.VentaId = id;
        }

        public async Task<Venta?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Venta>(
                "procObtenerVentas",
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Actualizar(int usuarioId, Venta venta)
        {
            using var connection = new SqlConnection(connectionString);
            var message = await connection.ExecuteAsync(
                "procAlteraVentas",
                new
                {
                    elementoAlterarId = venta.VentaId,
                    clienteId = venta.ClienteId,
                    descripcion = venta.Descripcion,
                    costoTotal = venta.CostoTotal,
                    fechaCreacion = venta.FechaCreacion,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.ExecuteAsync(
                "procAlteraVentas",
                new
                {
                    elementoAlterarId = id,
                    descripcion = "Venta eliminada",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}